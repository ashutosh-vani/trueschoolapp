class HomeworkItem {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String assignedBy;
  final String assignedDate;
  final String dueDate;
  final String status; // pending, in_progress, overdue, completed
  final String difficultyLevel;
  final int estimatedDurationMinutes;
  final int progressPercent;
  final String? grade;
  final String? teacherFeedback;
  final String submissionType; // online_quiz, file_upload, handwritten
  final bool aiAssistantEnabled;

  HomeworkItem({
    required this.id,
    required this.subject,
    required this.title,
    this.description = '',
    this.assignedBy = 'Teacher',
    this.assignedDate = '',
    this.dueDate = '',
    this.status = 'pending',
    this.difficultyLevel = 'medium',
    this.estimatedDurationMinutes = 30,
    this.progressPercent = 0,
    this.grade,
    this.teacherFeedback,
    this.submissionType = 'online_quiz',
    this.aiAssistantEnabled = true,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    return HomeworkItem(
      id: json['id'] ?? json['_id'] ?? '',
      subject: json['subject'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedBy: json['assignedBy'] ?? json['assigned_by'] ?? 'Teacher',
      assignedDate: json['assignedDate'] ?? json['assigned_date'] ?? '',
      dueDate: json['dueDate'] ?? json['due_date'] ?? '',
      status: json['status'] ?? 'pending',
      difficultyLevel: json['difficultyLevel'] ?? json['difficulty_level'] ?? 'medium',
      estimatedDurationMinutes: json['estimatedDurationMinutes'] ?? json['estimated_duration_minutes'] ?? 30,
      progressPercent: json['progressPercent'] ?? json['progress_percent'] ?? 0,
      grade: json['grade'],
      teacherFeedback: json['teacherFeedback'] ?? json['teacher_feedback'],
      submissionType: json['submissionType'] ?? json['submission_type'] ?? 'online_quiz',
      aiAssistantEnabled: json['ai_assistant_enabled'] ?? json['aiAssistantEnabled'] ?? true,
    );
  }
}
