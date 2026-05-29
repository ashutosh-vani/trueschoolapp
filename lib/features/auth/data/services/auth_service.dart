import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';

class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  AuthResult({required this.success, this.message, this.data});
}

class AuthService {
  static final String _baseUrl = AppConfig.apiUrl;

  /// Request OTP for phone-based login (students)
  /// POST /auth/otp/request
  static Future<AuthResult> requestOtp({
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/otp/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'role': role,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: body['message'] ?? 'OTP sent',
          data: body,
        );
      } else {
        return AuthResult(
          success: false,
          message: body['detail'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Verify OTP and get access token
  /// POST /auth/otp/verify
  static Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'role': role,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          data: body,
        );
      } else {
        return AuthResult(
          success: false,
          message: body['detail'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Email + password login (teacher, parent, schooladmin)
  /// POST /auth/login
  static Future<AuthResult> emailLogin({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          data: body,
        );
      } else {
        return AuthResult(
          success: false,
          message: body['detail'] ?? 'Invalid email or password',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Get current user profile
  /// GET /auth/me
  static Future<AuthResult> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(success: true, data: body);
      } else {
        return AuthResult(
          success: false,
          message: body['detail'] ?? 'Unauthorized',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error. Please check your connection.',
      );
    }
  }
}
