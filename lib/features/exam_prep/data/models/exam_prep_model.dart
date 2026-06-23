import 'package:flutter/foundation.dart';

class ExamPrepSubject {
  final String name;
  final String? examDate;
  final String syllabusType; // 'full' or 'select' / 'custom'
  final String? customTopics; // topics list joined by comma
  final List<String> topics;
  final String? examPattern; // 'mcq', 'mixed', 'descriptive', 'board'
  final String confidenceLevel; // 'low', 'medium', 'high'
  final int daysLeft;

  ExamPrepSubject({
    required this.name,
    this.examDate,
    this.syllabusType = 'full',
    this.customTopics,
    this.topics = const [],
    this.examPattern,
    this.confidenceLevel = 'medium',
    this.daysLeft = 0,
  });

  factory ExamPrepSubject.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'];
    List<String> topicsList = [];
    if (rawTopics is List) {
      topicsList = rawTopics.cast<String>();
    } else if (rawTopics is String) {
      topicsList = rawTopics.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    }
    return ExamPrepSubject(
      name: json['name'] ?? '',
      examDate: json['examDate'] ?? json['exam_date'],
      syllabusType: json['syllabusMode'] ?? json['syllabus_type'] ?? 'full',
      topics: topicsList,
      customTopics: json['custom_topics'] ?? topicsList.join(', '),
      examPattern: json['pattern'] ?? json['exam_pattern'],
      confidenceLevel: json['confidence'] ?? json['confidence_level'] ?? 'medium',
      daysLeft: json['daysLeft'] ?? json['days_left'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'examDate': examDate ?? '',
        'daysLeft': daysLeft,
        'syllabusMode': syllabusType == 'select' ? 'custom' : syllabusType,
        'topics': topics.isNotEmpty ? topics : (customTopics != null ? customTopics!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() : <String>[]),
        'pattern': examPattern ?? 'mixed',
        'confidence': confidenceLevel,
      };
}

class CreateExamPrepRequest {
  final String studentClass;
  final String board;
  final List<ExamPrepSubject> subjects;
  final int dailyStudyMinutes;
  final bool startQuiz;

  CreateExamPrepRequest({
    required this.studentClass,
    required this.board,
    required this.subjects,
    required this.dailyStudyMinutes,
    required this.startQuiz,
  });

  Map<String, dynamic> toJson() => {
        'class': studentClass.replaceAll('Class ', ''),
        'board': board,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'dailyStudyMinutes': dailyStudyMinutes,
      };
}

class ExamPrepPlan {
  final String id;
  final String studentClass;
  final String board;
  final List<String> subjects;
  final List<ExamPrepSubject> rawSubjects;
  final String dailyStudyTime;
  final String status; // 'active', 'completed', 'paused', 'upcoming'
  final String createdAt;
  final int? daysLeft;
  final int? progressPercent;

  ExamPrepPlan({
    required this.id,
    required this.studentClass,
    required this.board,
    required this.subjects,
    this.rawSubjects = const [],
    required this.dailyStudyTime,
    this.status = 'active',
    this.createdAt = '',
    this.daysLeft,
    this.progressPercent,
  });

  static String calculatePlanStatus(List<ExamPrepSubject> subjects) {
    if (subjects.isEmpty) return 'active';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool allPast = true;
    bool anyActive = false;

    for (final s in subjects) {
      if (s.examDate == null || s.examDate!.isEmpty) {
        allPast = false;
        continue;
      }
      try {
        final parsedDate = DateTime.parse(s.examDate!);
        final examDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        if (examDay.isBefore(today)) {
          // past exam
        } else {
          allPast = false;

          final diff = examDay.difference(today).inDays;
          if (diff >= 0 && diff <= 30) {
            anyActive = true;
          }
        }
      } catch (_) {
        allPast = false;
      }
    }

    if (allPast) return 'completed';
    if (anyActive) return 'active';
    return 'upcoming';
  }

  factory ExamPrepPlan.fromJson(Map<String, dynamic> json) {
    debugPrint('[ExamPrepPlan] parsing: $json');
    final rawSubjectsJson = json['subjects'] as List<dynamic>? ?? [];
    final List<ExamPrepSubject> parsedSubjects = rawSubjectsJson
        .map((s) {
          if (s is Map) {
            return ExamPrepSubject.fromJson(s.cast<String, dynamic>());
          }
          return ExamPrepSubject(name: s.toString());
        })
        .toList();

    final studentClass = json['class'] ?? json['student_class'] ?? json['grade'] ?? '';
    final status = json['status'] ?? calculatePlanStatus(parsedSubjects);

    return ExamPrepPlan(
      id: json['id'] ?? json['_id'] ?? json['plan_id'] ?? '',
      studentClass: studentClass,
      board: json['board'] ?? '',
      subjects: parsedSubjects.map((s) => s.name).toList(),
      rawSubjects: parsedSubjects,
      dailyStudyTime: (json['dailyStudyMinutes'] ?? json['daily_study_time'] ?? '').toString(),
      status: status,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      daysLeft: json['days_left'] ?? json['daysLeft'],
      progressPercent: json['progress_percent'] ?? json['progressPercent'],
    );
  }

  /// Parse from the real /student/exams response shape
  factory ExamPrepPlan.fromExamJson(Map<String, dynamic> json) {
    debugPrint('[ExamPrepPlan.fromExamJson] parsing: $json');
    final subjectName = json['subject'] ?? json['name'] ?? '';
    final daysLeft = json['daysLeft'] ?? json['days_left'];
    final daysLeftInt = daysLeft is int ? daysLeft : int.tryParse(daysLeft?.toString() ?? '');

    final subject = ExamPrepSubject(
      name: subjectName,
      examDate: json['date'] ?? json['exam_date'] ?? '',
      daysLeft: daysLeftInt ?? 0,
    );

    return ExamPrepPlan(
      id: json['id'] ?? json['_id'] ?? '',
      studentClass: json['class'] ?? json['student_class'] ?? json['grade'] ?? '',
      board: json['board'] ?? '',
      subjects: subjectName.isNotEmpty ? [subjectName] : [],
      rawSubjects: [subject],
      dailyStudyTime: '',
      status: 'active',
      createdAt: json['date'] ?? json['exam_date'] ?? '',
      daysLeft: daysLeftInt,
      progressPercent: json['readinessPercent'] ?? json['readiness_percent'],
    );
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

// ── Day Plan (from /exam-prep/{id}/full-plan) ────────────────────────────────

class DayPlanTask {
  final String id;
  final String subject;
  final String topic;
  final String taskType; // 'revise', 'importantq', 'notes', 'practice', 'last_day'
  final int durationMinutes;
  bool done;

  DayPlanTask({
    required this.id,
    required this.subject,
    required this.topic,
    required this.taskType,
    required this.durationMinutes,
    this.done = false,
  });

  factory DayPlanTask.fromJson(Map<String, dynamic> json) => DayPlanTask(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? json['title'] ?? '',
        taskType: json['task_type'] ?? json['taskType'] ?? 'revise',
        durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 15,
        done: json['done'] ?? false,
      );
}

class DayPlan {
  final int dayNumber;
  final String date;
  final String label; // 'REVISION', 'LAST_DAY', etc.
  final int totalMinutes;
  final List<DayPlanTask> tasks;

  DayPlan({
    required this.dayNumber,
    required this.date,
    required this.label,
    required this.totalMinutes,
    required this.tasks,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((t) => DayPlanTask.fromJson(t as Map<String, dynamic>))
        .toList();
    final totalMins = json['total_minutes'] ??
        tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    return DayPlan(
      dayNumber: json['day_number'] ?? json['dayNumber'] ?? 1,
      date: json['date'] ?? '',
      label: json['label'] ?? json['mode'] ?? 'REVISION',
      totalMinutes: totalMins,
      tasks: tasks,
    );
  }
}

// ── Notes & Practice Subject Entry ───────────────────────────────────────────

class SubjectNotes {
  final String subject;
  final List<String> noteTypes; // e.g. ['Short notes', 'Key concepts', 'Formulas']

  SubjectNotes({required this.subject, required this.noteTypes});

  factory SubjectNotes.fromJson(Map<String, dynamic> json) => SubjectNotes(
        subject: json['subject'] ?? '',
        noteTypes: (json['note_types'] ?? json['noteTypes'] as List<dynamic>? ?? [])
            .cast<String>(),
      );
}

class SubjectPractice {
  final String subject;
  final List<String> practiceTypes; // e.g. ['MCQ', 'Short Answer', 'Adaptive']

  SubjectPractice({required this.subject, required this.practiceTypes});

  factory SubjectPractice.fromJson(Map<String, dynamic> json) => SubjectPractice(
        subject: json['subject'] ?? '',
        practiceTypes:
            (json['practice_types'] ?? json['practiceTypes'] as List<dynamic>? ?? [])
                .cast<String>(),
      );
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
