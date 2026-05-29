import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/routes/app_router.dart';
import 'package:trueschoolapp/app/theme/app_theme.dart';

class TrueSchoolApp extends StatelessWidget {
  final bool isLoggedIn;

  const TrueSchoolApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueSchoolAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: isLoggedIn ? AppRouter.studentHome : AppRouter.roleSelection,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
