import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final String time;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.time,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawDate = json['created_at'] ?? json['createdAt'];
    if (rawDate != null) {
      try {
        createdAt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    return NotificationItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'homework_new').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['desc'] ?? json['message'] ?? '').toString(),
      read: json['read'] == true,
      time: (json['time'] ?? '').toString(),
      createdAt: createdAt,
    );
  }

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      time: time,
      createdAt: createdAt,
    );
  }

  // ── Visual helpers ──────────────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case 'homework_due':
        return Icons.schedule_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'overdue':
        return Icons.error_rounded;
      case 'teacher_message':
        return Icons.school_rounded;
      case 'homework_new':
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'homework_due':
        return const Color(0xFFF97316); // orange
      case 'achievement':
        return const Color(0xFF16A34A); // green
      case 'overdue':
        return const Color(0xFFDC2626); // red
      case 'teacher_message':
        return const Color(0xFF2563EB); // blue
      case 'homework_new':
      default:
        return const Color(0xFF5B4CDB); // primary purple
    }
  }

  Color get iconBg {
    switch (type) {
      case 'homework_due':
        return const Color(0xFFFFF7ED);
      case 'achievement':
        return const Color(0xFFF0FDF4);
      case 'overdue':
        return const Color(0xFFFEF2F2);
      case 'teacher_message':
        return const Color(0xFFEFF6FF);
      case 'homework_new':
      default:
        return const Color(0xFFEEEBFB);
    }
  }

  Color get borderColor {
    switch (type) {
      case 'homework_due':
        return const Color(0xFFF97316);
      case 'achievement':
        return const Color(0xFF16A34A);
      case 'overdue':
        return const Color(0xFFDC2626);
      case 'teacher_message':
        return const Color(0xFF2563EB);
      case 'homework_new':
      default:
        return const Color(0xFF5B4CDB);
    }
  }

  String get displayTime {
    if (time.isNotEmpty) return time;
    if (createdAt != null) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${createdAt!.day} ${months[createdAt!.month - 1]}';
    }
    return '';
  }
}
