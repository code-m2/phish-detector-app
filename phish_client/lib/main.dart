import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/analyzer_page.dart';
import 'pages/detection_history_page.dart';
import 'pages/notifications_page.dart';
import 'pages/stats_page.dart';


void main() {
  runApp(const PhishApp());
}

class PhishApp extends StatelessWidget {
  const PhishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, authService, __) => ApiService(
            auth: authService,
            baseUrl: "http://127.0.0.1:8000",
          ),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Phishing Email Detector',

        // 🌈 --------------------------- GLOBAL UI DESIGN ---------------------------
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,

          // 🔵 Global TextField Style
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            labelStyle: const TextStyle(fontSize: 16),
          ),

          // 🔵 Global Button Style
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 🔵 Global Typography
          textTheme: const TextTheme(
            headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(fontSize: 16),
          ),
        ),
        // -------------------------------------------------------------------------

        home: const RootRouter(),

        routes: {
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignupPage(),
          '/home': (_) => const HomePage(),
          '/analyzer': (_) => const AnalyzerPage(),
          '/history': (_) => const DetectionHistoryPage(),
          '/notifications': (_) => const NotificationsPage(),
          '/stats': (_) => const StatsPage(),
        },
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Auto-redirect to login if not logged in
    if (auth.token == null) {
      return const LoginPage();
    } else {
      return const HomePage();
    }
  }
}