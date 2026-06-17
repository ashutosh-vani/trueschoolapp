// ─────────────────────────────────────────────────────────────────────────────
// Learning Gap models — mirrors the web frontend data shapes exactly
// ─────────────────────────────────────────────────────────────────────────────

// ── Gap Health ────────────────────────────────────────────────────────────────

class GapHealth {
  final int score;
  final int maxScore;
  final String trend;
  final String improvementMessage;
  final int totalGaps;
  final String totalGapsTrend;
  final int resolvedGaps;
  final String resolvedGapsTrend;
  final GapSeverityCounts severity;

  const GapHealth({
    required this.score,
    required this.maxScore,
    required this.trend,
    required this.improvementMessage,
    required this.totalGaps,
    required this.totalGapsTrend,
    required this.resolvedGaps,
    required this.resolvedGapsTrend,
    required this.severity,
  });

  factory GapHealth.fromJson(Map<String, dynamic> j) => GapHealth(
        score: (j['score'] ?? 100) as int,
        maxScore: (j['maxScore'] ?? 100) as int,
        trend: j['trend'] ?? '',
        improvementMessage: j['improvementMessage'] ?? '',
        totalGaps: (j['totalGaps'] ?? 0) as int,
        totalGapsTrend: j['totalGapsTrend'] ?? '',
        resolvedGaps: (j['resolvedGaps'] ?? 0) as int,
        resolvedGapsTrend: j['resolvedGapsTrend'] ?? '',
        severity: GapSeverityCounts.fromJson(
            (j['severity'] as Map<String, dynamic>?) ?? {}),
      );

  static const fallback = GapHealth(
    score: 100,
    maxScore: 100,
    trend: '',
    improvementMessage: 'Loading your learning data...',
    totalGaps: 0,
    totalGapsTrend: '',
    resolvedGaps: 0,
    resolvedGapsTrend: '',
    severity: GapSeverityCounts(critical: 0, moderate: 0, minor: 0),
  );
}

class GapSeverityCounts {
  final int critical;
  final int moderate;
  final int minor;

  const GapSeverityCounts({
    required this.critical,
    required this.moderate,
    required this.minor,
  });

  factory GapSeverityCounts.fromJson(Map<String, dynamic> j) =>
      GapSeverityCounts(
        critical: (j['critical'] ?? 0) as int,
        moderate: (j['moderate'] ?? 0) as int,
        minor: (j['minor'] ?? 0) as int,
      );

  int get total => critical + moderate + minor;
}

// ── Learning Gap ──────────────────────────────────────────────────────────────

class CorrectivePath {
  final String type;
  final String label;
  final String detail;
  final String icon;

  const CorrectivePath({
    required this.type,
    required this.label,
    required this.detail,
    required this.icon,
  });

  factory CorrectivePath.fromJson(Map<String, dynamic> j) => CorrectivePath(
        type: j['type'] ?? '',
        label: j['label'] ?? '',
        detail: j['detail'] ?? '',
        icon: j['icon'] ?? 'help',
      );
}

class Prerequisite {
  final String topic;
  final int masteryPercent;
  final String status; // mastered | weak | current

  const Prerequisite({
    required this.topic,
    required this.masteryPercent,
    required this.status,
  });

  factory Prerequisite.fromJson(Map<String, dynamic> j) => Prerequisite(
        topic: j['topic'] ?? '',
        masteryPercent: (j['masteryPercent'] ?? 0) as int,
        status: j['status'] ?? 'weak',
      );
}

class GapAttempt {
  final int attemptNumber;
  final int score;
  final String date;

  const GapAttempt({
    required this.attemptNumber,
    required this.score,
    required this.date,
  });

  factory GapAttempt.fromJson(Map<String, dynamic> j) => GapAttempt(
        attemptNumber: (j['attemptNumber'] ?? j['attempt_number'] ?? 1) as int,
        score: (j['score'] ?? 0) as int,
        date: j['date'] ?? '',
      );
}

class VisualRef {
  final String label;
  final String detail;

  const VisualRef({required this.label, required this.detail});

  factory VisualRef.fromJson(Map<String, dynamic> j) =>
      VisualRef(label: j['label'] ?? '', detail: j['detail'] ?? '');
}

class RetryQuestion {
  final String text;
  final String? equation;
  final String type; // typed | mcq

  const RetryQuestion({
    required this.text,
    this.equation,
    required this.type,
  });

  factory RetryQuestion.fromJson(Map<String, dynamic> j) => RetryQuestion(
        text: j['text'] ?? '',
        equation: j['equation'] as String?,
        type: j['type'] ?? 'typed',
      );
}

class IdentifiedFrom {
  final String title;
  final String type;
  final String date;

  const IdentifiedFrom({
    required this.title,
    required this.type,
    required this.date,
  });

  factory IdentifiedFrom.fromJson(Map<String, dynamic> j) => IdentifiedFrom(
        title: j['title'] ?? '',
        type: j['type'] ?? '',
        date: j['date'] ?? '',
      );
}

class LearningGap {
  final String id;
  final String subject;
  final String topic;
  final String subtopic;
  final String severity; // critical | moderate | minor
  final String status; // active | resolved | in_progress
  final IdentifiedFrom identifiedFrom;
  final String impactAnalysis;
  final String impactSubject;
  final String prerequisiteDependency;
  final String prerequisiteSubject;
  final int masteryPercent;
  final int recommendedTimeMinutes;
  final List<GapAttempt> attempts;
  final List<Prerequisite> prerequisites;
  final List<CorrectivePath> correctivePath;
  final String aiErrorSummary;
  final String aiLastFeedback;
  final VisualRef? visualRef;
  final RetryQuestion? retryQuestion;

  const LearningGap({
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
    this.retryQuestion,
  });

  factory LearningGap.fromJson(Map<String, dynamic> j) => LearningGap(
        id: j['id'] ?? j['_id'] ?? '',
        subject: j['subject'] ?? '',
        topic: j['topic'] ?? '',
        subtopic: j['subtopic'] ?? '',
        severity: j['severity'] ?? 'minor',
        status: j['status'] ?? 'active',
        identifiedFrom: j['identifiedFrom'] != null
            ? IdentifiedFrom.fromJson(
                j['identifiedFrom'] as Map<String, dynamic>)
            : const IdentifiedFrom(title: '', type: '', date: ''),
        impactAnalysis: j['impactAnalysis'] ?? '',
        impactSubject: j['impactSubject'] ?? '',
        prerequisiteDependency: j['prerequisiteDependency'] ?? '',
        prerequisiteSubject: j['prerequisiteSubject'] ?? '',
        masteryPercent: (j['masteryPercent'] ?? 0) as int,
        recommendedTimeMinutes: (j['recommendedTimeMinutes'] ?? 30) as int,
        attempts: (j['attempts'] as List<dynamic>?)
                ?.map((a) => GapAttempt.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        prerequisites: (j['prerequisites'] as List<dynamic>?)
                ?.map((p) => Prerequisite.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        correctivePath: (j['correctivePath'] as List<dynamic>?)
                ?.map((c) =>
                    CorrectivePath.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        aiErrorSummary: j['aiErrorSummary'] ?? '',
        aiLastFeedback: j['aiLastFeedback'] ?? '',
        visualRef: j['visualRef'] != null
            ? VisualRef.fromJson(j['visualRef'] as Map<String, dynamic>)
            : null,
        retryQuestion: j['retryQuestion'] != null
            ? RetryQuestion.fromJson(
                j['retryQuestion'] as Map<String, dynamic>)
            : null,
      );
}

// ── Quiz ──────────────────────────────────────────────────────────────────────

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory QuizOption.fromJson(Map<String, dynamic> j) => QuizOption(
        id: j['id'] ?? '',
        text: j['text'] ?? '',
        isCorrect: j['isCorrect'] ?? false,
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

  const QuizQuestion({
    required this.id,
    required this.number,
    required this.difficulty,
    required this.prompt,
    this.equation,
    required this.options,
    required this.explanation,
    required this.hint,
  });

  QuizOption? get correctOption =>
      options.cast<QuizOption?>().firstWhere(
            (o) => o!.isCorrect,
            orElse: () => null,
          );

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] ?? '',
        number: (j['number'] ?? 1) as int,
        difficulty: j['difficulty'] ?? 'Easy',
        prompt: j['prompt'] ?? '',
        equation: j['equation'] as String?,
        options: (j['options'] as List<dynamic>?)
                ?.map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
        explanation: j['explanation'] ?? '',
        hint: j['hint'] ?? '',
      );
}

class QuizSummary {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final String difficulty; // easy | medium | hard
  final int totalQuestions;
  final int estimatedMinutes;

  const QuizSummary({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.totalQuestions,
    required this.estimatedMinutes,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> j) => QuizSummary(
        id: j['id'] ?? j['_id'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        topic: j['topic'] ?? '',
        difficulty: j['difficulty'] ?? 'easy',
        totalQuestions: (j['totalQuestions'] ??
                (j['questions'] as List?)?.length ??
                0) as int,
        estimatedMinutes: (j['estimatedMinutes'] ?? 0) as int,
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

  const Quiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.totalQuestions,
    required this.estimatedMinutes,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> j) => Quiz(
        id: j['id'] ?? j['_id'] ?? '',
        title: j['title'] ?? '',
        subject: j['subject'] ?? '',
        topic: j['topic'] ?? '',
        difficulty: j['difficulty'] ?? 'easy',
        totalQuestions:
            (j['totalQuestions'] ?? (j['questions'] as List?)?.length ?? 0)
                as int,
        estimatedMinutes: (j['estimatedMinutes'] ?? 0) as int,
        questions: (j['questions'] as List<dynamic>?)
                ?.map(
                    (q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ── Quiz Submit ───────────────────────────────────────────────────────────────

class QuizAnswer {
  final String questionId;
  final String selectedOptionId;

  const QuizAnswer({
    required this.questionId,
    required this.selectedOptionId,
  });

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
      };
}

class QuizResult {
  final int scorePct;
  final int correct;
  final int total;
  final bool resolved;

  const QuizResult({
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.resolved,
  });

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        scorePct: (j['score_pct'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
        total: (j['total'] ?? 0) as int,
        resolved: j['resolved'] ?? false,
      );
}

// ── AI Remediation Content ────────────────────────────────────────────────────

class RemediationContent {
  final String explanation;
  final List<String> keyPoints;
  final List<String> examples;

  const RemediationContent({
    required this.explanation,
    required this.keyPoints,
    required this.examples,
  });

  factory RemediationContent.fromJson(Map<String, dynamic> j) =>
      RemediationContent(
        explanation: j['explanation'] ?? '',
        keyPoints: (j['key_points'] as List<dynamic>?)?.cast<String>() ?? [],
        examples: (j['examples'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}
