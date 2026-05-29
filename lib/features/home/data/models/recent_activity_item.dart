import 'package:flutter/material.dart';

class RecentActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String status;
  final IconData icon;
  final DateTime? timestamp;

  RecentActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    this.status = '',
    this.timestamp,
  });

  /// Parse from GET /homework/student response item
  factory RecentActivityItem.fromHomework(Map<String, dynamic> json) {
    final status = (json['status'] ?? 'pending').toString();
    final title = (json['title'] ?? '').toString();
    final subject = (json['subject'] ?? '').toString();

    // Use assignedDate first, fall back to dueDate for timestamp
    final assignedDate = (json['assignedDate'] ?? json['assigned_date'] ?? '').toString();
    final dueDate = (json['dueDate'] ?? json['due_date'] ?? '').toString();
    final dateStr = assignedDate.isNotEmpty ? assignedDate : dueDate;

    String displayTitle;
    String activityType;

    switch (status) {
      case 'completed':
        displayTitle = 'Completed: $title';
        activityType = 'homework_completed';
        break;
      case 'overdue':
        displayTitle = 'Overdue: $title';
        activityType = 'homework_overdue';
        break;
      case 'in_progress':
        displayTitle = 'In Progress: $title';
        activityType = 'homework_in_progress';
        break;
      default:
        displayTitle = 'Assigned: $title';
        activityType = 'homework_assigned';
    }

    DateTime? parsedDate;
    if (dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr);
    }

    return RecentActivityItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: displayTitle,
      subtitle: subject,
      type: activityType,
      status: status,
      icon: _iconForStatus(status),
      timestamp: parsedDate,
    );
  }

  /// Parse from GET /student/notifications response item
  factory RecentActivityItem.fromNotification(Map<String, dynamic> json) {
    final type = json['type'] ?? 'general';
    final title = json['title'] ?? json['message'] ?? '';
    final subtitle = json['subject'] ?? json['description'] ?? '';
    final createdAt = json['created_at'] ?? json['timestamp'] ?? '';

    DateTime? parsedDate;
    if (createdAt.isNotEmpty) {
      parsedDate = DateTime.tryParse(createdAt.toString());
    }

    return RecentActivityItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: title,
      subtitle: subtitle,
      type: type,
      status: '',
      icon: _iconForType(type),
      timestamp: parsedDate,
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'homework_assigned':
      case 'homework':
        return Icons.menu_book_outlined;
      case 'grade':
      case 'graded':
        return Icons.grade_outlined;
      case 'exam':
        return Icons.description_outlined;
      case 'attendance':
        return Icons.calendar_today_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static IconData _iconForStatus(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outlined;
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'in_progress':
        return Icons.edit_note_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }
}
