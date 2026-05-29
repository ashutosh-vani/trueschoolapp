import 'package:flutter/foundation.dart';

class ExamPrepSubject {
  final String name;
  final String? examDate;
  final String syllabusType; // 'full' or 'select'
  final String? customTopics;
  final String? examPattern; // 'mcq', 'mixed', 'descriptive', 'board'
  final String confidenceLevel; // 'low', 'medium', 'high'

  ExamPrepSubject({
    required this.name,
    this.examDate,
    this.syllabusType = 'full',
    this.customTopics,
    this.examPattern,
    this.confidenceLevel = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'exam_date': examDate,
        'syllabus_type': syllabusType,
        'custom_topics': customTopics,
        'exam_pattern': examPattern,
        'confidence_level': confidenceLevel,
      };
}

class CreateExamPrepRequest {
  final String studentClass;
  final String board;
  final List<ExamPrepSubject> subjects;
  final String dailyStudyTime; // '30min', '1hr', '2hr', '3hr+'
  final bool startQuiz;

  CreateExamPrepRequest({
    required this.studentClass,
    required this.board,
    required this.subjects,
    required this.dailyStudyTime,
    required this.startQuiz,
  });

  Map<String, dynamic> toJson() => {
        'student_class': studentClass,
        'board': board,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'daily_study_time': dailyStudyTime,
        'start_quiz': startQuiz,
      };
}

class ExamPrepPlan {
  final String id;
  final String studentClass;
  final String board;
  final List<String> subjects;
  final String dailyStudyTime;
  final String status; // 'active', 'completed', 'paused'
  final String createdAt;
  final int? daysLeft;
  final int? progressPercent;

  ExamPrepPlan({
    required this.id,
    required this.studentClass,
    required this.board,
    required this.subjects,
    required this.dailyStudyTime,
    this.status = 'active',
    this.createdAt = '',
    this.daysLeft,
    this.progressPercent,
  });

  factory ExamPrepPlan.fromJson(Map<String, dynamic> json) {
    debugPrint('[ExamPrepPlan] parsing: $json');
    return ExamPrepPlan(
      id: json['id'] ?? json['_id'] ?? json['plan_id'] ?? '',
      studentClass: json['student_class'] ?? json['class'] ?? json['grade'] ?? '',
      board: json['board'] ?? '',
      subjects: _parseSubjects(json['subjects']),
      dailyStudyTime: json['daily_study_time'] ?? json['study_time'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      daysLeft: json['days_left'] ?? json['daysLeft'],
      progressPercent: json['progress_percent'] ?? json['progressPercent'],
    );
  }

  /// Parse from the real /student/exams response shape
  factory ExamPrepPlan.fromExamJson(Map<String, dynamic> json) {
    debugPrint('[ExamPrepPlan.fromExamJson] parsing: $json');
    // Each exam is one subject — wrap it as a single-subject plan
    final subject = json['subject'] ?? json['name'] ?? '';
    final daysLeft = json['daysLeft'] ?? json['days_left'];
    return ExamPrepPlan(
      id: json['id'] ?? json['_id'] ?? '',
      studentClass: json['class'] ?? json['student_class'] ?? json['grade'] ?? '',
      board: json['board'] ?? '',
      subjects: subject.isNotEmpty ? [subject] : [],
      dailyStudyTime: '',
      status: 'active',
      createdAt: json['date'] ?? json['exam_date'] ?? '',
      daysLeft: daysLeft is int ? daysLeft : int.tryParse(daysLeft?.toString() ?? ''),
      progressPercent: json['readinessPercent'] ?? json['readiness_percent'],
    );
  }

  static List<String> _parseSubjects(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((s) {
        if (s is String) return s;
        if (s is Map) return (s['name'] ?? s['subject'] ?? '').toString();
        return s.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String) return [raw];
    return [];
  }
}

// ── Plan Detail models ────────────────────────────────────────────────────────

class ReadinessSubject {
  final String subject;
  final int readinessPercent;

  ReadinessSubject({required this.subject, required this.readinessPercent});

  factory ReadinessSubject.fromJson(Map<String, dynamic> json) => ReadinessSubject(
        subject: json['subject'] ?? '',
        readinessPercent: json['readiness_percent'] ?? json['readinessPercent'] ?? 0,
      );
}

class ReadinessReport {
  final int overallPercent;
  final String predictedScoreRange;
  final List<ReadinessSubject> subjects;

  ReadinessReport({
    required this.overallPercent,
    required this.predictedScoreRange,
    required this.subjects,
  });

  factory ReadinessReport.fromJson(Map<String, dynamic> json) => ReadinessReport(
        overallPercent: json['overall_percent'] ?? json['overallPercent'] ?? 0,
        predictedScoreRange: json['predicted_score_range'] ?? json['predictedScoreRange'] ?? '',
        subjects: (json['subjects'] as List<dynamic>?)
                ?.map((s) => ReadinessSubject.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class StudyTask {
  final String id;
  final String subject;
  final String topic;
  final String taskType; // 'revise', 'importantq', 'practice', 'notes'
  final int durationMinutes;
  bool done;

  StudyTask({
    required this.id,
    required this.subject,
    required this.topic,
    required this.taskType,
    required this.durationMinutes,
    this.done = false,
  });

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? json['title'] ?? '',
        taskType: json['task_type'] ?? json['taskType'] ?? 'revise',
        durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 15,
        done: json['done'] ?? false,
      );
}

class UpcomingExam {
  final String id;
  final String subject;
  final String examType; // 'MCQ', 'Mixed', 'Descriptive', 'Board Pattern'
  final String date;
  final int daysLeft;
  final int readinessPercent;
  final String confidenceLevel;

  UpcomingExam({
    required this.id,
    required this.subject,
    required this.examType,
    required this.date,
    required this.daysLeft,
    required this.readinessPercent,
    required this.confidenceLevel,
  });

  factory UpcomingExam.fromJson(Map<String, dynamic> json) => UpcomingExam(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        examType: json['exam_type'] ?? json['examType'] ?? 'MCQ',
        date: json['date'] ?? json['exam_date'] ?? '',
        daysLeft: json['days_left'] ?? json['daysLeft'] ?? 0,
        readinessPercent: json['readiness_percent'] ?? json['readinessPercent'] ?? 0,
        confidenceLevel: json['confidence_level'] ?? json['confidenceLevel'] ?? 'medium',
      );
}

class ExamPrepDetail {
  final String id;
  final String studentClass;
  final String board;
  final String mode; // 'revision', 'normal'
  final ReadinessReport readinessReport;
  final List<String> aiTips;
  final List<StudyTask> todayTasks;
  final List<UpcomingExam> upcomingExams;
  final int totalMinutesToday;
  final int tasksDoneToday;

  ExamPrepDetail({
    required this.id,
    required this.studentClass,
    required this.board,
    required this.mode,
    required this.readinessReport,
    required this.aiTips,
    required this.todayTasks,
    required this.upcomingExams,
    required this.totalMinutesToday,
    required this.tasksDoneToday,
  });

  factory ExamPrepDetail.fromJson(Map<String, dynamic> json) {
    final tasks = (json['today_tasks'] ?? json['todayTasks'] as List<dynamic>? ?? [])
        .map((t) => StudyTask.fromJson(t as Map<String, dynamic>))
        .toList();
    final done = tasks.where((t) => t.done).length;
    final totalMins = tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);

    return ExamPrepDetail(
      id: json['id'] ?? json['_id'] ?? '',
      studentClass: json['student_class'] ?? '',
      board: json['board'] ?? '',
      mode: json['mode'] ?? 'normal',
      readinessReport: json['readiness_report'] != null
          ? ReadinessReport.fromJson(json['readiness_report'] as Map<String, dynamic>)
          : ReadinessReport(overallPercent: 0, predictedScoreRange: '', subjects: []),
      aiTips: (json['ai_tips'] as List<dynamic>?)?.cast<String>() ?? [],
      todayTasks: tasks,
      upcomingExams: (json['upcoming_exams'] ?? json['upcomingExams'] as List<dynamic>? ?? [])
          .map((e) => UpcomingExam.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMinutesToday: json['total_minutes_today'] ?? totalMins,
      tasksDoneToday: json['tasks_done_today'] ?? done,
    );
  }
}

// ── Revision Task (from /student/revision-tasks) ─────────────────────────────
class RevisionTask {
  final String id;
  final String subject;
  final String topic;
  final String duration;
  bool done;
  final String priority; // 'high', 'medium', 'low'

  RevisionTask({
    required this.id,
    required this.subject,
    required this.topic,
    required this.duration,
    this.done = false,
    this.priority = 'medium',
  });

  factory RevisionTask.fromJson(Map<String, dynamic> json) => RevisionTask(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? json['title'] ?? '',
        duration: json['duration'] ?? '',
        done: json['done'] ?? false,
        priority: json['priority'] ?? 'medium',
      );

  /// Convert to StudyTask for the detail page
  StudyTask toStudyTask() => StudyTask(
        id: id,
        subject: subject,
        topic: topic,
        taskType: priority == 'high' ? 'importantq' : 'revise',
        durationMinutes: _parseDurationMinutes(duration),
        done: done,
      );

  static int _parseDurationMinutes(String dur) {
    if (dur.contains('hr')) {
      return (double.tryParse(dur.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1).round() * 60;
    }
    return int.tryParse(dur.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;
  }
}

// ── Study Stats (from /student/study-stats) ───────────────────────────────────
class StudyStats {
  final int studyStreak;
  final double totalStudyHoursThisWeek;

  StudyStats({required this.studyStreak, required this.totalStudyHoursThisWeek});

  factory StudyStats.fromJson(Map<String, dynamic> json) => StudyStats(
        studyStreak: json['studyStreak'] ?? json['study_streak'] ?? 0,
        totalStudyHoursThisWeek:
            (json['totalStudyHoursThisWeek'] ?? json['total_study_hours_this_week'] ?? 0)
                .toDouble(),
      );
}
