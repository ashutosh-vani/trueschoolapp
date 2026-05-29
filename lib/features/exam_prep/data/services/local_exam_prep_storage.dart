import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores student-created exam prep plans locally on device.
/// Each plan is stored as a JSON object in SharedPreferences.
/// Key: 'local_exam_preps' → JSON array of plan objects.
class LocalExamPrepStorage {
  static const _key = 'local_exam_preps';

  /// Save a new plan. Returns the saved plan with a generated id.
  static Future<Map<String, dynamic>> savePlan({
    required String studentClass,
    required String board,
    required List<Map<String, dynamic>> subjects, // [{name, examDate, examPattern, confidenceLevel, syllabusType, customTopics}]
    required String dailyStudyTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getPlans();

    final plan = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'student_class': studentClass,
      'board': board,
      'subjects': subjects,
      'daily_study_time': dailyStudyTime,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'active',
    };

    existing.add(plan);
    await prefs.setString(_key, jsonEncode(existing));
    debugPrint('[LocalExamPrepStorage] saved plan: ${plan['id']}');
    return plan;
  }

  /// Get all locally stored plans.
  static Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[LocalExamPrepStorage] getPlans error: $e');
      return [];
    }
  }

  /// Delete a plan by id.
  static Future<void> deletePlan(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await getPlans();
    plans.removeWhere((p) => p['id'] == id);
    await prefs.setString(_key, jsonEncode(plans));
    debugPrint('[LocalExamPrepStorage] deleted plan: $id');
  }

  /// Convert a locally stored plan into _WebExam-compatible maps
  /// (one map per subject, matching the /student/exams response shape).
  static List<Map<String, dynamic>> planToExamCards(Map<String, dynamic> plan) {
    final subjects = (plan['subjects'] as List<dynamic>?) ?? [];
    return subjects.map((s) {
      final sub = s as Map<String, dynamic>;
      final examDate = sub['examDate'] as String?;
      int daysLeft = 0;
      if (examDate != null && examDate.isNotEmpty) {
        try {
          final date = DateTime.parse(examDate);
          daysLeft = date.difference(DateTime.now()).inDays;
          if (daysLeft < 0) daysLeft = 0;
        } catch (_) {}
      }

      // Build syllabus from customTopics or use subject name
      List<String> syllabus = [];
      final customTopics = sub['customTopics'] as String?;
      if (customTopics != null && customTopics.isNotEmpty) {
        syllabus = customTopics.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }

      final confidence = sub['confidenceLevel'] as String? ?? 'medium';
      final readiness = confidence == 'high' ? 75 : confidence == 'low' ? 25 : 50;

      return {
        'id': '${plan['id']}_${sub['name']}',
        'subject': sub['name'] ?? '',
        'examType': _patternLabel(sub['examPattern'] as String?),
        'date': examDate ?? '',
        'daysLeft': daysLeft,
        'syllabus': syllabus,
        'readinessPercent': readiness,
        'isLocal': true,
        'planId': plan['id'],
      };
    }).toList();
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
}
