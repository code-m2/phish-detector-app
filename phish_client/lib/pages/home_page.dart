import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalScans = 0;
  int phishingDetected = 0;

  bool loading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchStats();
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchStats();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final res = await api.getDashboardStats();

    if (!mounted) return;

    if (res["statusCode"] == 200) {
      setState(() {
        totalScans = res["body"]["total"];
        phishingDetected = res["body"]["phishing"];
        loading = false;
      });
    }
  }

  // Popup notification helper
  void showNotificationPopup(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget statCard(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget navButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1E88E5),
            ],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back,",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "User",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          statCard("Total Scans", totalScans, Icons.search),
                          const SizedBox(width: 14),
                          statCard("Phishing Detected",
                              phishingDetected, Icons.warning_amber),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Start analyzing emails",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Scan suspicious messages and detect phishing instantly.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 220,
                              child: navButton(
                                "Open Analyzer",
                                Icons.shield,
                                () {
                                  Navigator.pushNamed(context, '/analyzer');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: navButton(
                              "History",
                              Icons.history,
                              () {
                                Navigator.pushNamed(context, '/history');
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: navButton(
                              "Daily Report",
                              Icons.bar_chart,
                              () {
                                Navigator.pushNamed(context, '/stats');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      const Center(
                        child: Text(
                          "Phishing Detector © 2025",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
