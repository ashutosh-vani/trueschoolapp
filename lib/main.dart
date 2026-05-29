import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trueschoolapp/app/app.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Check if user is already logged in
  final isLoggedIn = await TokenStorage.isLoggedIn();

  runApp(TrueSchoolApp(isLoggedIn: isLoggedIn));
}
