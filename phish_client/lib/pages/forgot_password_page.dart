import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_background.dart';
import '../services/auth_service.dart';
import 'verify_reset_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: AuthBackground(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Forgot Password",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Enter your email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);

                          final res = await auth.forgotPassword(emailCtrl.text.trim());

                          setState(() => loading = false);

                          if (res['statusCode'] == 200) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerifyResetPage(email: emailCtrl.text.trim()),
                              ),
                            );
                          } else {
                            _error(res['body']);
                          }
                        },
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Send Reset Code"),
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _error(dynamic msg) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(title: const Text("Error"), content: Text(msg.toString())),
    );
  }
}
