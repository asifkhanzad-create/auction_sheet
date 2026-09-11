import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'admin_theme.dart';
import 'admin_auth_service.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auction Sheet — Admin',
      debugShowCheckedModeBanner: false,
      // Admin panel follows the system brightness — no manual toggle.
      // themeMode defaults to ThemeMode.system when both are set.
      theme: AdminTheme.light(),
      darkTheme: AdminTheme.dark(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AdminAuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null || !AdminAuthService.isAllowed(user)) {
          return const AdminLoginScreen();
        }

        return const AdminDashboardScreen();
      },
    );
  }
}
