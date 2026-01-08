import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import 'new_password_page.dart';

class VerifyResetPage extends StatefulWidget {
  final String email;
  const VerifyResetPage({super.key, required this.email});

  @override
  State<VerifyResetPage> createState() => _VerifyResetPageState();
}

class _VerifyResetPageState extends State<VerifyResetPage> {
  final codeCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

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
                const Text("Reset Verification",
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Text("Enter the code sent to:", style: const TextStyle(fontSize: 14)),
                Text(widget.email,
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "6-digit Code",
                    prefixIcon: Icon(Icons.verified_user),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);

                          final res = await auth.verifyResetCode(
                              widget.email, codeCtrl.text.trim());

                          setState(() => loading = false);

                          if (res['statusCode'] == 200) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NewPasswordPage(email: widget.email),
                              ),
                            );
                          } else {
                            _err(res['body']);
                          }
                        },
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify Code"),
                ),

                TextButton(
                  onPressed: () => auth.resendResetCode(widget.email),
                  child: const Text("Resend Code"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _err(dynamic msg) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(title: const Text("Invalid Code"), content: Text(msg.toString())),
    );
  }
}
