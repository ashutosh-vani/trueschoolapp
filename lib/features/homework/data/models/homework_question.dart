class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;

  QuestionOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] ?? json['_id'] ?? '',
      text: json['text'] ?? json['label'] ?? '',
      isCorrect: json['is_correct'] ?? json['isCorrect'] ?? false,
    );
  }
}

class HomeworkQuestion {
  final String id;
  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final String answerType; // mcq, typed, upload
  final List<QuestionOption> options;
  final String? hint;
  final String? vinNudge;
  final int maxPoints;
  final String? sampleAnswer;

  HomeworkQuestion({
    required this.id,
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.answerType,
    this.options = const [],
    this.hint,
    this.vinNudge,
    this.maxPoints = 1,
    this.sampleAnswer,
  });

  factory HomeworkQuestion.fromJson(Map<String, dynamic> json) {
    return HomeworkQuestion(
      id: json['id'] ?? json['_id'] ?? '',
      questionNumber: (json['questionNumber'] as num?)?.toInt() ??
          (json['question_number'] as num?)?.toInt() ??
          1,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ??
          (json['total_questions'] as num?)?.toInt() ??
          1,
      questionText: json['questionText'] ?? json['question_text'] ?? '',
      answerType: json['answerType'] ?? json['answer_type'] ?? 'mcq',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) {
                if (o is Map) {
                  return QuestionOption.fromJson(Map<String, dynamic>.from(o));
                }
                return QuestionOption(id: '', text: o.toString());
              })
              .toList() ??
          [],
      hint: json['hint'],
      vinNudge: json['vinNudge'] ?? json['vin_nudge'],
      maxPoints: (json['maxPoints'] as num?)?.toInt() ??
          (json['max_points'] as num?)?.toInt() ??
          1,
      sampleAnswer: json['sampleAnswer'] ?? json['sample_answer'],
    );
  }
}
