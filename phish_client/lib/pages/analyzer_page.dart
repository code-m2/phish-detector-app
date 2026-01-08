import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  final subject = TextEditingController();
  final content = TextEditingController();

  String? result;
  double? confidence;
  List<String> suggestions = [];
  bool loading = false;

  // ---------------- HELPERS ----------------

  List<String> extractUrls(String text) {
    final regex = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  bool detectAttachment(String text) {
    final t = text.toLowerCase();
    return t.contains(".pdf") ||
        t.contains(".doc") ||
        t.contains(".docx") ||
        t.contains("attachment") ||
        t.contains("attached file");
  }

  // ---------------- ANALYZE ----------------

  Future<void> analyze() async {
    setState(() => loading = true);

    final api = Provider.of<ApiService>(context, listen: false);

    final bodyText = content.text.trim();
    final urls = extractUrls(bodyText);

    final payload = {
      "subject": subject.text.trim(),
      "text": bodyText,
      "sender_domain": "",
      "links_count": urls.length,
      "has_attachment": detectAttachment(bodyText) ? 1 : 0,
      "urls": urls,
      "source": "manual",
    };

    final res = await api.analyzeAndLog(payload);
    setState(() => loading = false);

    if (res["statusCode"] == 200) {
      final det = res["body"]["detection"];
      setState(() {
        result = det["prediction"];
        confidence = det["combined_score"];
        suggestions = List<String>.from(det["suggestions"]);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error analyzing email")),
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF1E88E5),
              Color(0xFF283593),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // 🔙 TOP BAR WITH BACK BUTTON
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Email Phishing Detector",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // INPUT CARD
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: subject,
                          decoration: const InputDecoration(
                            labelText: "Subject",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: content,
                          minLines: 6,
                          maxLines: 12,
                          decoration: const InputDecoration(
                            labelText: "Email Body",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : analyze,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  const Color.fromARGB(255, 70, 149, 227),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "Analyze Email",
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // RESULT CARD
                if (result != null)
                  Card(
                    elevation: 6,
                    color: result == "phishing"
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result == "phishing"
                                ? "PHISHING DETECTED"
                                : "LEGITIMATE EMAIL",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: result == "phishing"
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Confidence: ${(confidence! * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // SUGGESTIONS
                if (suggestions.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: suggestions
                            .map(
                              (s) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text("• $s"),
                              ),
                            )
                            .toList(),
                      ),
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
