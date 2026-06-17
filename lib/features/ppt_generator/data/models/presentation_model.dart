/// Data models for the AI Presentation Generator feature.
/// Mirrors the JSON schema returned by POST /teacher/ai-tool { tool: "presentation" }

class PresentationSlide {
  final int number;
  final String type; // title | objectives | hook | content | example | activity | summary | assessment
  final String title;
  final String? subtitle;
  final String? content;
  final List<String> bullets;
  final List<String> steps;
  final List<String> questions;
  final String? instructions;
  final String? explanation;
  final String? speakerNotes;
  final int? durationMinutes;
  final String? engagementPrompt;

  const PresentationSlide({
    required this.number,
    required this.type,
    required this.title,
    this.subtitle,
    this.content,
    this.bullets = const [],
    this.steps = const [],
    this.questions = const [],
    this.instructions,
    this.explanation,
    this.speakerNotes,
    this.durationMinutes,
    this.engagementPrompt,
  });

  factory PresentationSlide.fromJson(Map<String, dynamic> json) {
    return PresentationSlide(
      number: (json['number'] as num?)?.toInt() ?? 0,
      type: json['type'] ?? 'content',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      content: json['content'],
      bullets:
          (json['bullets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      questions:
          (json['questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      instructions: json['instructions'],
      explanation: json['explanation'],
      speakerNotes: json['speaker_notes'],
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      engagementPrompt: json['engagement_prompt'],
    );
  }
}

class PresentationResult {
  final String title;
  final String subject;
  final String grade;
  final int totalSlides;
  final int durationMinutes;
  final List<String> learningObjectives;
  final List<PresentationSlide> slides;
  final String? teacherPreparationNotes;
  final String? homeworkConnection;

  const PresentationResult({
    required this.title,
    required this.subject,
    required this.grade,
    required this.totalSlides,
    required this.durationMinutes,
    required this.learningObjectives,
    required this.slides,
    this.teacherPreparationNotes,
    this.homeworkConnection,
  });

  factory PresentationResult.fromJson(Map<String, dynamic> json) {
    final slideList = (json['slides'] as List<dynamic>?)
            ?.map((e) => PresentationSlide.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PresentationResult(
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      grade: json['grade'] ?? '',
      totalSlides: (json['total_slides'] as num?)?.toInt() ?? slideList.length,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      learningObjectives: (json['learning_objectives'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      slides: slideList,
      teacherPreparationNotes: json['teacher_preparation_notes'],
      homeworkConnection: json['homework_connection'],
    );
  }
}
