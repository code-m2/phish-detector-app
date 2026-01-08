import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class DetectionHistoryPage extends StatefulWidget {
  const DetectionHistoryPage({super.key});

  @override
  State<DetectionHistoryPage> createState() => _DetectionHistoryPageState();
}

class _DetectionHistoryPageState extends State<DetectionHistoryPage> {
  List detections = [];
  bool loading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchHistory();
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchHistory());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchHistory() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final res = await api.getDetections(limit: 100);

    if (!mounted) return;
    setState(() {
      detections = res["body"]["detections"] ?? [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detection History"),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
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
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : detections.isEmpty
                ? const Center(
                    child: Text("No detections yet", style: TextStyle(color: Colors.white70)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: detections.length,
                    itemBuilder: (_, i) {
                      final d = detections[i];
                      final isPhish = d["prediction"] == "phishing";

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: isPhish ? Colors.red.shade50 : Colors.green.shade50,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            isPhish ? Icons.warning_rounded : Icons.check_circle,
                            color: isPhish ? Colors.red : Colors.green,
                          ),
                          title: Text(d["subject"] ?? "No Subject"),
                          subtitle: Text(d["timestamp"] ?? ""),
                          trailing: Text(
                            d["prediction"].toString().toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPhish ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
