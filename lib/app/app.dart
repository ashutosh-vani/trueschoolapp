import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/routes/app_router.dart';
import 'package:trueschoolapp/app/theme/app_theme.dart';

class TrueSchoolApp extends StatelessWidget {
  const TrueSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueSchoolAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.roleSelection,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
