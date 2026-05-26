import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';

enum UserRole {
  student,
  parent,
  teacher,
  schoolAdmin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.schoolAdmin:
        return 'School Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.parent:
        return Icons.people_outlined;
      case UserRole.teacher:
        return Icons.menu_book_outlined;
      case UserRole.schoolAdmin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case UserRole.student:
        return AppColors.studentGradient;
      case UserRole.parent:
        return AppColors.parentGradient;
      case UserRole.teacher:
        return AppColors.teacherGradient;
      case UserRole.schoolAdmin:
        return AppColors.adminGradient;
    }
  }
}
