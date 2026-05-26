import 'package:flutter/material.dart';
import 'package:trueschoolapp/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:trueschoolapp/features/auth/presentation/pages/phone_input_page.dart';
import 'package:trueschoolapp/features/auth/presentation/pages/role_selection_page.dart';
import 'package:trueschoolapp/features/home/presentation/pages/student_home_page.dart';

class AppRouter {
  static const String roleSelection = '/';
  static const String phoneInput = '/phone-input';
  static const String otpVerification = '/otp-verification';
  static const String studentHome = '/student-home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        );
      case phoneInput:
        final role = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PhoneInputPage(role: role),
        );
      case otpVerification:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            phoneNumber: args['phoneNumber']!,
            role: args['role']!,
          ),
        );
      case studentHome:
        return MaterialPageRoute(
          builder: (_) => const StudentHomePage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
