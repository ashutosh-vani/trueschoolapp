// Models for the Learning Gaps feature
// Mirrors the web learningGapData.js and learningGapsSlice.js data shapes

// ── Gap Health ─────────────────────────────────────────────────────────────────
class GapSeverityCounts {
  final int critical;
  final int moderate;
  final int minor;

  GapSeverityCounts({
    required this.critical,
    required this.moderate,
    required this.minor,
  });

  factory GapSeverityCounts.fromJson(Map<String, dynamic> json) =>
      GapSeverityCounts(
        critical: json['critical'] ?? 0,
        moderate: json['moderate'] ?? 0,
        minor: json['minor'] ?? 0,
      );
}

class GapHealth {
  final int score;
  final int maxScore;
  final String trend;
  final String trendDirection;
  final String improvementMessage;
  final int totalGaps;
  final String totalGapsTrend;
  final int resolvedGaps;
  final String resolvedGapsTrend;
  final GapSeverityCounts severity;

  GapHealth({
    required this.score,
    required this.maxScore,
    required this.trend,
    required this.trendDirection,
    required this.improvementMessage,
    required this.totalGaps,
    required this.totalGapsTrend,
    required this.resolvedGaps,
    required this.resolvedGapsTrend,
    required this.severity,
  });

  factory GapHealth.fromJson(Map<String, dynamic> json) => GapHealth(
        score: json['score'] ?? 0,
        maxScore: json['maxScore'] ?? json['max_score'] ?? 100,
        trend: json['trend'] ?? '',
        trendDirection: json['trendDirection'] ?? json['trend_direction'] ?? 'up',
        improvementMessage: json['improvementMessage'] ?? json['improvement_message'] ?? '',
        totalGaps: json['totalGaps'] ?? json['total_gaps'] ?? 0,
        totalGapsTrend: json['totalGapsTrend'] ?? json['total_gaps_trend'] ?? '',
        resolvedGaps: json['resolvedGaps'] ?? json['resolved_gaps'] ?? 0,
        resolvedGapsTrend: json['resolvedGapsTrend'] ?? json['resolved_gaps_trend'] ?? '',
        severity: json['severity'] != null
            ? GapSeverityCounts.fromJson(json['severity'] as Map<String, dynamic>)
            : GapSeverityCounts(critical: 0, moderate: 0, minor: 0),
      );
}

// ── Identified From ────────────────────────────────────────────────────────────
class IdentifiedFrom {
  final String title;
  final String type; // quiz | homework | test
  final String date;

  IdentifiedFrom({required this.title, required this.type, required this.date});

  factory IdentifiedFrom.fromJson(Map<String, dynamic> json) => IdentifiedFrom(
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        date: json['date'] ?? '',
      );
}

// ── Prerequisite ────────────────────────────────────────────────────────────────
class GapPrerequisite {
  final String topic;
  final int masteryPercent;
  final String status; // mastered | weak | current

  GapPrerequisite({
    required this.topic,
    required this.masteryPercent,
    required this.status,
  });

  factory GapPrerequisite.fromJson(Map<String, dynamic> json) => GapPrerequisite(
        topic: json['topic'] ?? '',
        masteryPercent: json['masteryPercent'] ?? json['mastery_percent'] ?? 0,
        status: json['status'] ?? 'weak',
      );
}

// ── Corrective Path Item ────────────────────────────────────────────────────────
class CorrectivePathItem {
  final String type; // video | reading | practice
  final String label;
  final String detail;
  final String icon;

  CorrectivePathItem({
    required this.type,
    required this.label,
    required this.detail,
    required this.icon,
  });

  factory CorrectivePathItem.fromJson(Map<String, dynamic> json) =>
      CorrectivePathItem(
        type: json['type'] ?? '',
        label: json['label'] ?? '',
        detail: json['detail'] ?? '',
        icon: json['icon'] ?? '',
      );
}

// ── Attempt ────────────────────────────────────────────────────────────────────
class GapAttempt {
  final int attemptNumber;
  final int score;
  final String date;

  GapAttempt({
    required this.attemptNumber,
    required this.score,
    required this.date,
  });

  factory GapAttempt.fromJson(Map<String, dynamic> json) => GapAttempt(
        attemptNumber: json['attemptNumber'] ?? json['attempt_number'] ?? 0,
        score: json['score'] ?? 0,
        date: json['date'] ?? '',
      );
}

// ── Retry Question ─────────────────────────────────────────────────────────────
class RetryQuestion {
  final String text;
  final String? equation;
  final String type; // typed | mcq

  RetryQuestion({required this.text, this.equation, required this.type});

  factory RetryQuestion.fromJson(Map<String, dynamic> json) => RetryQuestion(
        text: json['text'] ?? '',
        equation: json['equation'],
        type: json['type'] ?? 'typed',
      );
}

// ── Visual Ref ─────────────────────────────────────────────────────────────────
class VisualRef {
  final String label;
  final String detail;

  VisualRef({required this.label, required this.detail});

  factory VisualRef.fromJson(Map<String, dynamic> json) => VisualRef(
        label: json['label'] ?? '',
        detail: json['detail'] ?? '',
      );
}

// ── Learning Gap ───────────────────────────────────────────────────────────────
class LearningGap {
  final String id;
  final String subject;
  final String topic;
  final String subtopic;
  final String severity; // critical | moderate | minor
  final String status;   // active | resolved | in_progress
  final IdentifiedFrom identifiedFrom;
  final String impactAnalysis;
  final String impactSubject;
  final String prerequisiteDependency;
  final String prerequisiteSubject;
  final int masteryPercent;
  final int recommendedTimeMinutes;
  final List<GapAttempt> attempts;
  final List<GapPrerequisite> prerequisites;
  final List<CorrectivePathItem> correctivePath;
  final String aiErrorSummary;
  final String aiLastFeedback;
  final VisualRef? visualRef;
  final RetryQuestion retryQuestion;

  LearningGap({
    required this.id,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.severity,
    required this.status,
    required this.identifiedFrom,
    required this.impactAnalysis,
    required this.impactSubject,
    required this.prerequisiteDependency,
    required this.prerequisiteSubject,
    required this.masteryPercent,
    required this.recommendedTimeMinutes,
    required this.attempts,
    required this.prerequisites,
    required this.correctivePath,
    required this.aiErrorSummary,
    required this.aiLastFeedback,
    this.visualRef,
    required this.retryQuestion,
  });

  factory LearningGap.fromJson(Map<String, dynamic> json) => LearningGap(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? '',
        subtopic: json['subtopic'] ?? '',
        severity: json['severity'] ?? 'minor',
        status: json['status'] ?? 'active',
        identifiedFrom: json['identifiedFrom'] != null
            ? IdentifiedFrom.fromJson(json['identifiedFrom'] as Map<String, dynamic>)
            : IdentifiedFrom(title: '', type: '', date: ''),
        impactAnalysis: json['impactAnalysis'] ?? json['impact_analysis'] ?? '',
        impactSubject: json['impactSubject'] ?? json['impact_subject'] ?? '',
        prerequisiteDependency:
            json['prerequisiteDependency'] ?? json['prerequisite_dependency'] ?? '',
        prerequisiteSubject: json['prerequisiteSubject'] ?? json['prerequisite_subject'] ?? '',
        masteryPercent: json['masteryPercent'] ?? json['mastery_percent'] ?? 0,
        recommendedTimeMinutes:
            json['recommendedTimeMinutes'] ?? json['recommended_time_minutes'] ?? 0,
        attempts: (json['attempts'] as List<dynamic>? ?? [])
            .map((a) => GapAttempt.fromJson(a as Map<String, dynamic>))
            .toList(),
        prerequisites: (json['prerequisites'] as List<dynamic>? ?? [])
            .map((p) => GapPrerequisite.fromJson(p as Map<String, dynamic>))
            .toList(),
        correctivePath: (json['correctivePath'] as List<dynamic>? ?? [])
            .map((c) => CorrectivePathItem.fromJson(c as Map<String, dynamic>))
            .toList(),
        aiErrorSummary: json['aiErrorSummary'] ?? json['ai_error_summary'] ?? '',
        aiLastFeedback: json['aiLastFeedback'] ?? json['ai_last_feedback'] ?? '',
        visualRef: json['visualRef'] != null
            ? VisualRef.fromJson(json['visualRef'] as Map<String, dynamic>)
            : null,
        retryQuestion: json['retryQuestion'] != null
            ? RetryQuestion.fromJson(json['retryQuestion'] as Map<String, dynamic>)
            : RetryQuestion(text: '', type: 'typed'),
      );
}

// ── Remediation Content ────────────────────────────────────────────────────────
class RemediationContent {
  final String? explanation;
  final List<String> keyPoints;
  final List<String> examples;

  RemediationContent({
    this.explanation,
    required this.keyPoints,
    required this.examples,
  });

  factory RemediationContent.fromJson(Map<String, dynamic> json) =>
      RemediationContent(
        explanation: json['explanation'],
        keyPoints: (json['key_points'] as List<dynamic>? ?? []).cast<String>(),
        examples: (json['examples'] as List<dynamic>? ?? []).cast<String>(),
      );
}

class GapRemediation {
  final LearningGap gap;
  final RemediationContent? remediation;

  GapRemediation({required this.gap, this.remediation});

  factory GapRemediation.fromJson(Map<String, dynamic> json) => GapRemediation(
        gap: LearningGap.fromJson(json['gap'] as Map<String, dynamic>),
        remediation: json['remediation'] != null
            ? RemediationContent.fromJson(
                json['remediation'] as Map<String, dynamic>)
            : null,
      );
}

// ── Quiz Models ────────────────────────────────────────────────────────────────
class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  QuizOption({required this.id, required this.text, required this.isCorrect});

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        isCorrect: json['isCorrect'] ?? json['is_correct'] ?? false,
      );
}

class QuizQuestion {
  final String id;
  final int number;
  final String difficulty;
  final String prompt;
  final String? equation;
  final List<QuizOption> options;
  final String explanation;
  final String hint;

  QuizQuestion({
    required this.id,
    required this.number,
    required this.difficulty,
    required this.prompt,
    this.equation,
    required this.options,
    required this.explanation,
    required this.hint,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] ?? json['_id'] ?? '',
        number: json['number'] ?? 0,
        difficulty: json['difficulty'] ?? '',
        prompt: json['prompt'] ?? '',
        equation: json['equation'],
        options: (json['options'] as List<dynamic>? ?? [])
            .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        explanation: json['explanation'] ?? '',
        hint: json['hint'] ?? '',
      );
}

class Quiz {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final String difficulty;
  final int totalQuestions;
  final int estimatedMinutes;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.totalQuestions,
    required this.estimatedMinutes,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] ?? json['_id'] ?? '',
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        topic: json['topic'] ?? '',
        difficulty: json['difficulty'] ?? 'easy',
        totalQuestions: json['totalQuestions'] ?? json['total_questions'] ?? 0,
        estimatedMinutes: json['estimatedMinutes'] ?? json['estimated_minutes'] ?? 0,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}
