// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  String? token;
  String userName = "";
  String userEmail = "";

  final String baseUrl = "http://127.0.0.1:8000";

  bool get isLoggedIn => token != null;

  // =========================================================
  // SIGNUP
  // =========================================================
  Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    userName = name;
    userEmail = email;

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body)
    };
  }

  // =========================================================
  // VERIFY ACCOUNT CODE
  // =========================================================
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    final url = Uri.parse('$baseUrl/auth/verify_code');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

  // =========================================================
  // RESEND SIGNUP CODE
  // =========================================================
  Future<Map<String, dynamic>> resendCode(String email) async {
    final url = Uri.parse('$baseUrl/auth/resend_code');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return {
      "statusCode": response.statusCode,
      "body": jsonDecode(response.body),
    };
  }

  // =========================================================
  // LOGIN
  // =========================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      token = data["access_token"];
      userName = data["name"] ?? email.split("@")[0];
      userEmail = email;
      notifyListeners();
    }

    return {"statusCode": response.statusCode, "body": data};
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot_password');

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}));

    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    final url = Uri.parse('$baseUrl/auth/verify_reset_code');

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}));

    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> setNewPassword(
      String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/auth/set_new_password');

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "new_password": newPassword}));

    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> updatePassword( 
      String email, String newPassword) async { 
    return await setNewPassword(email, newPassword); }

  Future<Map<String, dynamic>> resendResetCode(String email) async {
    final url = Uri.parse('$baseUrl/auth/resend_reset_code');

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}));

    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // =========================================================
  // GET DAILY STATS (Fix for stats_page & dashboard)
  // =========================================================
  Future<Map<String, dynamic>> getDailyStats() async {
    if (token == null) {
      return {"error": "Not logged in"};
    }

    final url = Uri.parse('$baseUrl/stats/today');

    final res = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    });

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> analyze(String subject, String body) async {
  final url = Uri.parse('$baseUrl/analyze');

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "subject": subject,
      "body": body,
    }),
  );

  return {
    "statusCode": response.statusCode,
    "body": jsonDecode(response.body),
  };
}


  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> logout() async {
    token = null;
    userName = "";
    userEmail = "";
    notifyListeners();
  }
}
