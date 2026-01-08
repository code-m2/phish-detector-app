import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';

class VerifyPage extends StatefulWidget {
  final String email;
  const VerifyPage({super.key, required this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Verify Email",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Text("A 6-digit code was sent to:",
                  style: const TextStyle(fontSize: 14)),
              Text(widget.email,
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Verification Code",
                    prefixIcon: Icon(Icons.verified)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() => loading = true);
                        final res = await auth.verifyCode(
                            widget.email, codeCtrl.text.trim());
                        setState(() => loading = false);

                        if (res['statusCode'] == 200) {
                          Navigator.pushReplacementNamed(context, "/login");
                        } else {
                          _err(res['body']);
                        }
                      },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),

              TextButton(
                onPressed: () => auth.resendCode(widget.email),
                child: const Text("Resend Code"),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _err(dynamic msg) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Verification Failed"),
              content: Text(msg.toString()),
            ));
  }
}
