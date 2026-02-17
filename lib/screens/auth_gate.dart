import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {

        // 🔹 Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 🔹 Logged In
        if (snapshot.hasData) {
          Posthog().screen(screenName: 'HomeScreen'); // Manual trigger
          return const HomeScreen();
        }

        // 🔹 Not Logged In
        Posthog().screen(screenName: 'LoginScreen'); // Manual trigger
        return LoginScreen();
      },
    );
  }
}
