// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService auth;
  final String baseUrl;

  ApiService({
    required this.auth,
    this.baseUrl = "http://127.0.0.1:8000",
  });

  // ----------------------------
  // DEFAULT HEADERS (AUTH TOKEN)
  // ----------------------------
  Map<String, String> _headers() {
    final headers = {"Content-Type": "application/json"};
    if (auth.token != null) {
      headers["Authorization"] = "Bearer ${auth.token}";
    }
    return headers;
  }

  // ----------------------------
  // GENERIC GET
  // ----------------------------
  Future<http.Response> get(String path) async {
    final url = Uri.parse("$baseUrl$path");
    return await http.get(url, headers: _headers());
  }

  // ----------------------------
  // GENERIC POST
  // ----------------------------
  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl$path");
    return await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(body),
    );
  }

  // ===========================================================
  // ===============  AUTHENTICATION METHODS  ==================
  // ===========================================================

  // SIGNUP
  Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    final res = await post("/auth/signup", {
      "name": name,
      "email": email,
      "password": password,
    });

    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  // VERIFY SIGNUP CODE
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    final res = await post("/auth/verify_code", {
      "email": email,
      "code": code,
    });
    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  // RESEND VERIFICATION CODE
  Future<Map<String, dynamic>> resendCode(String email) async {
    final res = await post("/auth/resend_code", {
      "email": email,
    });
    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post("/auth/login", {
      "email": email,
      "password": password,
    });

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      auth.token = data["access_token"];
      auth.notifyListeners();
    }

    return {"statusCode": res.statusCode, "body": data};
  }

  // FORGOT PASSWORD
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await post("/auth/forgot_password", {"email": email});
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // VERIFY RESET CODE
  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code) async {
    final res = await post("/auth/verify_reset_code", {
      "email": email,
      "code": code,
    });
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // SET NEW PASSWORD
  Future<Map<String, dynamic>> setNewPassword(
      String email, String newPassword) async {
    final res = await post("/auth/set_new_password", {
      "email": email,
      "new_password": newPassword,
    });
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // ===========================================================
  // ===============     ANALYZER & LOGGING     ===============
  // ===========================================================

// ANALYZE + SAVE TO HISTORY + CREATE NOTIFICATION
  Future<Map<String, dynamic>> analyzeAndLog(
      Map<String, dynamic> payload) async {
    final res = await post("/api/analyze_and_log", payload);

    try {
      return {
        "statusCode": res.statusCode,
        "body": jsonDecode(res.body),
      };
    } catch (e) {
      // If response is not JSON, return raw body
      return {
        "statusCode": res.statusCode,
        "body": {"error": res.body},
      };
    }
  }

  // GET DETECTION HISTORY
  Future<Map<String, dynamic>> getDetections(
      {int limit = 50, int offset = 0}) async {
    final res = await get("/api/detections?limit=$limit&offset=$offset");

    return {
      "statusCode": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }

  // ===========================================================
  // ===============      NOTIFICATIONS        ===============
  // ===========================================================

  // GET NOTIFICATIONS
  Future<Map<String, dynamic>> getNotifications() async {
    final res = await get("/api/notifications");
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // MARK NOTIFICATION AS READ
  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    final res = await post("/api/notifications/mark_read", {
      "notification_id": id,
    });
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // ===========================================================
  // ===============         STATS API        =================
  // ===========================================================

  // DAILY STATS
  Future<Map<String, dynamic>> getStatsDaily({int days = 30}) async {
    final res = await get("/api/stats/daily?days=$days");
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  // PROGRESS STATS (current vs previous)
  Future<Map<String, dynamic>> getStatsProgress({int days = 7}) async {
    final res = await get("/api/stats/progress?days=$days");
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> getTotals() async {
    final res = await get("/api/detections?limit=1000");
    final data = jsonDecode(res.body)["detections"];

    int phishing = 0;
    for (var d in data) {
      if (d["prediction"] == "phishing") phishing++;
    }

    return {
      "total": data.length,
      "phishing": phishing,
    };
  }

  Future<int> getUnreadCount() async {
    final res = await get("/api/notifications");
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final notes = data["notifications"] ?? [];
      final unread = notes.where((n) => n["read"] == false).length;
      return unread;
    }
    return 0;
  }


    // DASHBOARD STATS (HOME PAGE)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/stats/dashboard"),
        headers: _headers(), // ✅ FIXED
      );

      return {
        "statusCode": res.statusCode,
        "body": jsonDecode(res.body),
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "body": {"error": e.toString()},
      };
    }
  }



  // ===========================================================
  // ===============     USER SETTINGS API     ===============
  // ===========================================================

  Future<Map<String, dynamic>> setAutodetect(bool enabled) async {
    final res = await post("/api/settings/autodetect", {
      "enabled": enabled,
    });
    return {"statusCode": res.statusCode, "body": jsonDecode(res.body)};
  }
}
