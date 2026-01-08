import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import 'verify_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Create Account",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Full Name", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                    labelText: "Email", prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Password", prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() => loading = true);
                        final res = await auth.signup(
                            nameCtrl.text.trim(),
                            emailCtrl.text.trim(),
                            passCtrl.text.trim());

                        setState(() => loading = false);

                        if (res['statusCode'] == 200) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      VerifyPage(email: emailCtrl.text.trim())));
                        } else {
                          _error(res['body']);
                        }
                      },
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _error(dynamic msg) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Error"),
              content: Text(msg.toString()),
            ));
  }
}
