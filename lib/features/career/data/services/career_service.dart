import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trueschoolapp/config/app_config.dart';
import 'package:trueschoolapp/features/auth/data/services/token_storage.dart';
import 'package:trueschoolapp/features/career/data/models/career_domain.dart';

class CareerService {
  static final String _baseUrl = AppConfig.apiUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /career/domains
  static Future<List<CareerDomain>> getDomains() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/career/domains'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => CareerDomain.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /career/{domain_id}
  static Future<List<Career>> getCareersForDomain(String domainId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/career/$domainId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((d) => Career.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// GET /career/{domain_id}/{career_id}
  static Future<Career?> getCareerDetail(
      String domainId, String careerId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/career/$domainId/$careerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return Career.fromJson(data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
