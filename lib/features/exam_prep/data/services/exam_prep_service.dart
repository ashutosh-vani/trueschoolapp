import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
// re-export detail models used by the service
export 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart'
    show DayPlan, DayPlanTask, SubjectNotes, SubjectPractice;

class ExamPrepService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Expose auth headers publicly for pages that call multiple endpoints
  static Future<Map<String, String>> authHeaders() => _authHeaders();

  /// GET /student/exams → raw JSON list (matches web frontend exactly)
  static Future<List<Map<String, dynamic>>> getRawExams(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exams'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/exams → ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : [];
        debugPrint('[ExamPrepService] exams count: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getRawExams error: $e');
      return [];
    }
  }

  /// GET /student/revision-tasks — returns List of RevisionTask
  static Future<List<RevisionTask>> getRawRevisionTasks(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/student/revision-tasks'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/revision-tasks → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('[ExamPrepService] revision tasks count: ${data.length}');
        return data.map((d) => RevisionTask.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getRawRevisionTasks error: $e');
      return [];
    }
  }

  // ── Real backend endpoints ──────────────────────────────────────────────────

  /// GET /student/exams — list upcoming exams for this student
  /// Falls back to building plans from /student/revision-tasks if exams returns empty
  static Future<List<ExamPrepPlan>> getExamPreps() async {
    try {
      final headers = await _authHeaders();

      // Try /student/exams
      final examsResponse = await http.get(
        Uri.parse('$_baseUrl/student/exams'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/exams → ${examsResponse.statusCode}');

      List<ExamPrepPlan> plans = [];

      if (examsResponse.statusCode == 200) {
        final decoded = jsonDecode(examsResponse.body);
        final List<dynamic> data = decoded is List ? decoded : [];
        plans = data
            .map((d) => ExamPrepPlan.fromExamJson(d as Map<String, dynamic>))
            .toList();
      }

      // Also fetch revision_tasks — per-student
      final tasksResponse = await http.get(
        Uri.parse('$_baseUrl/student/revision-tasks'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/revision-tasks → ${tasksResponse.statusCode}');

      if (tasksResponse.statusCode == 200) {
        final List<dynamic> taskData = jsonDecode(tasksResponse.body);
        if (plans.isEmpty && taskData.isNotEmpty) {
          plans = _buildPlansFromRevisionTasks(taskData);
        }
      }

      // Return whatever the API gave us — empty list is valid (list page shows empty state)
      debugPrint('[ExamPrepService] final plans count: ${plans.length}');
      return plans;
    } catch (e, st) {
      debugPrint('[ExamPrepService] getExamPreps error: $e\n$st');
      return [];
    }
  }

  /// Build ExamPrepPlan list from revision tasks grouped by subject
  static List<ExamPrepPlan> _buildPlansFromRevisionTasks(List<dynamic> tasks) {
    // Group all tasks into one plan (matching the web frontend behavior)
    final subjects = <String>{};
    int doneCount = 0;
    for (final t in tasks) {
      final subject = (t['subject'] ?? 'General').toString();
      subjects.add(subject);
      if (t['done'] == true) doneCount++;
    }

    final progress = tasks.isEmpty ? 0 : ((doneCount / tasks.length) * 100).round();

    // Return a single plan card representing the student's exam prep
    return [
      ExamPrepPlan(
        id: 'revision_plan',
        studentClass: '',
        board: '',
        subjects: subjects.toList(),
        dailyStudyTime: '',
        status: 'active',
        createdAt: '',
        daysLeft: null,
        progressPercent: progress,
      ),
    ];
  }

  /// Fallback: pull exam prep data from /student/dashboard
  // ignore: unused_element
  static Future<List<ExamPrepPlan>> _getExamsFromDashboard(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/student/dashboard'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/dashboard → ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final examData = decoded['exam_prep'] ?? decoded['exams'] ?? decoded['upcoming_exams'];
        if (examData is List && examData.isNotEmpty) {
          return examData
              .map((d) => ExamPrepPlan.fromExamJson(d as Map<String, dynamic>))
              .toList();
        }
        final student = decoded['student'] as Map<String, dynamic>?;
        debugPrint('[ExamPrepService] student section_id: ${student?['section_id']}, class: ${student?['class']}');
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] dashboard fallback error: $e');
      return [];
    }
  }

  /// GET /student/revision-tasks — today's revision tasks
  static Future<List<RevisionTask>> getRevisionTasks() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/revision-tasks'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/revision-tasks → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => RevisionTask.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getRevisionTasks error: $e');
      return [];
    }
  }

  /// GET /student/study-stats — streak + weekly hours
  static Future<StudyStats?> getStudyStats() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/study-stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return StudyStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ExamPrepService] getStudyStats error: $e');
      return null;
    }
  }

  /// PATCH /student/revision-tasks/{taskId}/toggle
  static Future<bool> toggleRevisionTask(String taskId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/student/revision-tasks/$taskId/toggle'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExamPrepService] toggleRevisionTask error: $e');
      return false;
    }
  }

  // ── Kept for future exam-prep CRUD when backend adds it ────────────────────

  /// POST /exam-prep — create a new exam prep plan (future endpoint)
  static Future<ExamPrepPlan?> createExamPrep(CreateExamPrepRequest request) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode(request.toJson());
      debugPrint('[ExamPrepService] POST /exam-prep body: $body');
      final response = await http.post(
        Uri.parse('$_baseUrl/exam-prep'),
        headers: headers,
        body: body,
      );
      debugPrint('[ExamPrepService] POST /exam-prep → ${response.statusCode}: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ExamPrepPlan.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ExamPrepService] createExamPrep error: $e');
      return null;
    }
  }

  /// DELETE /exam-prep/{id}
  static Future<bool> deleteExamPrep(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/exam-prep/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[ExamPrepService] deleteExamPrep error: $e');
      return false;
    }
  }

  /// GET /exam-prep/{id} — plan detail
  static Future<ExamPrepDetail?> getExamPrepDetail(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/exam-prep/$id'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /exam-prep/$id → ${response.statusCode}');
      if (response.statusCode == 200) {
        return ExamPrepDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ExamPrepService] getExamPrepDetail error: $e');
      return null;
    }
  }

  /// PATCH /exam-prep/{planId}/tasks/{taskId}/toggle
  static Future<bool> toggleTask(String planId, String taskId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/exam-prep/$planId/tasks/$taskId/toggle'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExamPrepService] toggleTask error: $e');
      return false;
    }
  }

  /// PATCH /exam-prep/{id}/mode
  static Future<bool> toggleMode(String id, String mode) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/exam-prep/$id/mode'),
        headers: headers,
        body: jsonEncode({'mode': mode}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExamPrepService] toggleMode error: $e');
      return false;
    }
  }

  /// GET /exam-prep/{id}/full-plan — day-by-day study plan
  static Future<List<DayPlan>> getFullPlan(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/exam-prep/$id/full-plan'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /exam-prep/$id/full-plan → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => DayPlan.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getFullPlan error: $e');
      return [];
    }
  }

  /// GET /exam-prep/{id}/notes — per-subject notes
  static Future<List<SubjectNotes>> getNotes(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/exam-prep/$id/notes'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /exam-prep/$id/notes → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => SubjectNotes.fromJson(d as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getNotes error: $e');
      return [];
    }
  }

  /// GET /exam-prep/{id}/practice — per-subject practice sets
  static Future<List<SubjectPractice>> getPractice(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/exam-prep/$id/practice'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /exam-prep/$id/practice → ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((d) => SubjectPractice.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getPractice error: $e');
      return [];
    }
  }

  /// PATCH /exam-prep/{planId}/full-plan/tasks/{taskId}/toggle
  static Future<bool> toggleFullPlanTask(String planId, String taskId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/exam-prep/$planId/full-plan/tasks/$taskId/toggle'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExamPrepService] toggleFullPlanTask error: $e');
      return false;
    }
  }
}
