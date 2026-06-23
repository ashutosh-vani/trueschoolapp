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

  /// GET /student/exam-prep/list — list study plans for this student
  static Future<List<ExamPrepPlan>> getExamPreps() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exam-prep/list'),
        headers: headers,
      );
      debugPrint('[ExamPrepService] GET /student/exam-prep/list → ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : [];
        return data
            .map((d) => ExamPrepPlan.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, st) {
      debugPrint('[ExamPrepService] getExamPreps error: $e\n$st');
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

  // ── exam-prep CRUD ─────────────────────────────────────────────────────────

  /// POST /student/exam-prep/setup — create/setup a new exam prep plan
  static Future<ExamPrepPlan?> createExamPrep(CreateExamPrepRequest request) async {
    try {
      final headers = await _authHeaders();
      final body = jsonEncode(request.toJson());
      debugPrint('[ExamPrepService] POST /student/exam-prep/setup body: $body');
      final response = await http.post(
        Uri.parse('$_baseUrl/student/exam-prep/setup'),
        headers: headers,
        body: body,
      );
      debugPrint('[ExamPrepService] POST /student/exam-prep/setup → ${response.statusCode}: ${response.body}');
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

  /// DELETE /student/exam-prep/{id}
  static Future<bool> deleteExamPrep(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/student/exam-prep/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[ExamPrepService] deleteExamPrep error: $e');
      return false;
    }
  }

  /// GET /student/exam-prep/list matched by ID — plan detail
  static Future<ExamPrepDetail?> getExamPrepDetail(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exam-prep/list'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final plan = data.firstWhere((p) => p['id'] == id, orElse: () => data.isNotEmpty ? data.first : null);
        if (plan == null) return null;

        final studentClass = plan['class'] ?? '';
        final board = plan['board'] ?? '';

        final studyPlan = plan['studyPlan'] as List<dynamic>? ?? [];
        final todayPlanMap = studyPlan.isNotEmpty ? studyPlan.first as Map<String, dynamic> : null;
        final sessions = todayPlanMap != null ? (todayPlanMap['sessions'] as List<dynamic>? ?? []) : [];

        int taskIdx = 0;
        final todayTasks = sessions.map((s) {
          final sMap = s as Map<String, dynamic>;
          final type = sMap['type'] ?? 'Revise';
          return StudyTask(
            id: 'session_${todayPlanMap?['day'] ?? 1}_$taskIdx',
            subject: sMap['subject'] ?? '',
            topic: sMap['topic'] ?? '',
            taskType: type.toString().toLowerCase(),
            durationMinutes: sMap['duration'] ?? 15,
            done: sMap['done'] ?? false,
          );
        }).toList();

        final doneCount = todayTasks.where((t) => t.done).length;
        final totalMins = todayTasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);

        final rawSubjects = plan['subjects'] as List<dynamic>? ?? [];
        final readiness = plan['readiness'] as Map<String, dynamic>? ?? {};
        final upcomingExams = rawSubjects.map((s) {
          final sMap = s as Map<String, dynamic>;
          final name = sMap['name'] ?? '';
          final readinessPct = readiness[name] ?? 50;
          final confidence = sMap['confidence'] ?? 'medium';
          final daysLeft = sMap['daysLeft'] ?? 0;

          return UpcomingExam(
            id: '${plan['id']}_exam_$name',
            subject: name,
            examType: _patternLabel(sMap['pattern']),
            date: sMap['examDate'] ?? '',
            daysLeft: daysLeft is int ? daysLeft : int.tryParse(daysLeft.toString()) ?? 0,
            readinessPercent: readinessPct is int ? readinessPct : int.tryParse(readinessPct.toString()) ?? 50,
            confidenceLevel: confidence,
          );
        }).toList();

        final readinessSubjects = rawSubjects.map((s) {
          final name = (s as Map)['name'] ?? '';
          final pct = readiness[name] ?? 50;
          return ReadinessSubject(
            subject: name,
            readinessPercent: pct is int ? pct : int.tryParse(pct.toString()) ?? 50,
          );
        }).toList();

        final avgReadiness = readinessSubjects.isEmpty 
            ? 50 
            : (readinessSubjects.fold<int>(0, (sum, s) => sum + s.readinessPercent) / readinessSubjects.length).round();

        final predicted = '${avgReadiness - 10}-${avgReadiness + 10} marks';

        return ExamPrepDetail(
          id: plan['id'] ?? '',
          studentClass: studentClass,
          board: board,
          mode: plan['currentMode'] ?? 'normal',
          readinessReport: ReadinessReport(
            overallPercent: avgReadiness,
            predictedScoreRange: predicted,
            subjects: readinessSubjects,
          ),
          aiTips: (plan['aiInsights'] as List<dynamic>?)?.cast<String>() ?? [],
          todayTasks: todayTasks,
          upcomingExams: upcomingExams,
          totalMinutesToday: totalMins,
          tasksDoneToday: doneCount,
        );
      }
      return null;
    } catch (e, st) {
      debugPrint('[ExamPrepService] getExamPrepDetail error: $e\n$st');
      return null;
    }
  }

  static String _patternLabel(String? pattern) {
    switch (pattern) {
      case 'mcq':         return 'MCQ Based';
      case 'mixed':       return 'Mixed';
      case 'descriptive': return 'Descriptive';
      case 'board':       return 'Board Pattern';
      default:            return 'Exam';
    }
  }

  /// POST /student/exam-prep/session-progress
  static Future<bool> toggleTask(String planId, String taskId, {bool done = true}) async {
    try {
      final parts = taskId.split('_');
      if (parts.length >= 3 && parts[0] == 'session') {
        final day = int.tryParse(parts[1]) ?? 1;
        final idx = int.tryParse(parts[2]) ?? 0;

        final headers = await _authHeaders();
        final response = await http.post(
          Uri.parse('$_baseUrl/student/exam-prep/session-progress'),
          headers: headers,
          body: jsonEncode({
            'day': day,
            'session_index': idx,
            'done': done,
            'prep_id': planId.isNotEmpty ? planId : null,
          }),
        );
        debugPrint('[ExamPrepService] toggleTask response: ${response.statusCode}');
        return response.statusCode == 200;
      }
      return false;
    } catch (e) {
      debugPrint('[ExamPrepService] toggleTask error: $e');
      return false;
    }
  }

  /// PATCH /student/exam-prep/{id}/mode
  static Future<bool> toggleMode(String id, String mode) async {
    try {
      // Mocked locally as there's no mode PATCH endpoint on backend (regenerated via wizard / setup)
      return true;
    } catch (e) {
      return false;
    }
  }

  /// GET /student/exam-prep/list matched by ID — day-by-day study plan
  static Future<List<DayPlan>> getFullPlan(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exam-prep/list'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final plan = data.firstWhere((p) => p['id'] == id, orElse: () => null);
        if (plan == null) return [];

        final studyPlan = plan['studyPlan'] as List<dynamic>? ?? [];
        return studyPlan.map((d) {
          final dMap = d as Map<String, dynamic>;
          final dayNum = dMap['day'] ?? 1;
          final date = dMap['date'] ?? '';
          final mode = dMap['mode'] ?? 'regular';
          final totalMins = dMap['totalMinutes'] ?? 0;
          
          int taskIdx = 0;
          final tasks = (dMap['sessions'] as List<dynamic>? ?? []).map((s) {
            final sMap = s as Map<String, dynamic>;
            final type = sMap['type'] ?? 'Revise';
            return DayPlanTask(
              id: 'session_${dayNum}_$taskIdx',
              subject: sMap['subject'] ?? '',
              topic: sMap['topic'] ?? '',
              taskType: type.toString().toLowerCase(),
              durationMinutes: sMap['duration'] ?? 15,
              done: sMap['done'] ?? false,
            );
          }).toList();

          return DayPlan(
            dayNumber: dayNum,
            date: date,
            label: mode.toUpperCase(),
            totalMinutes: totalMins,
            tasks: tasks,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getFullPlan error: $e');
      return [];
    }
  }

  /// GET /student/exam-prep/list matched by ID — per-subject notes
  static Future<List<SubjectNotes>> getNotes(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exam-prep/list'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final plan = data.firstWhere((p) => p['id'] == id, orElse: () => null);
        if (plan == null) return [];

        final rawSubjects = plan['subjects'] as List<dynamic>? ?? [];
        return rawSubjects.map((s) {
          final name = (s as Map)['name'] ?? '';
          return SubjectNotes(
            subject: name,
            noteTypes: ['Short notes', 'Key concepts', 'Formulas'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getNotes error: $e');
      return [];
    }
  }

  /// GET /student/exam-prep/list matched by ID — per-subject practice sets
  static Future<List<SubjectPractice>> getPractice(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/exam-prep/list'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final plan = data.firstWhere((p) => p['id'] == id, orElse: () => null);
        if (plan == null) return [];

        final rawSubjects = plan['subjects'] as List<dynamic>? ?? [];
        return rawSubjects.map((s) {
          final name = (s as Map)['name'] ?? '';
          return SubjectPractice(
            subject: name,
            practiceTypes: ['MCQ', 'Short Answer', 'Adaptive'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExamPrepService] getPractice error: $e');
      return [];
    }
  }

  /// POST /student/exam-prep/session-progress
  static Future<bool> toggleFullPlanTask(String planId, String taskId, {bool done = true}) async {
    return toggleTask(planId, taskId, done: done);
  }
}
