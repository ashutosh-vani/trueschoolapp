class TaskItem {
  final String id;
  final String title;
  final String subject;
  final bool done;
  final bool isOptimistic; // true while waiting for server confirmation

  const TaskItem({
    required this.id,
    required this.title,
    this.subject = 'Custom',
    this.done = false,
    this.isOptimistic = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? 'Custom').toString(),
      done: json['done'] == true,
    );
  }

  TaskItem copyWith({String? id, bool? done, bool? isOptimistic}) {
    return TaskItem(
      id: id ?? this.id,
      title: title,
      subject: subject,
      done: done ?? this.done,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}
