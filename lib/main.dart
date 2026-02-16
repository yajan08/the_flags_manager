import 'package:flags_manager/screens/auth_gate.dart';
import 'package:flags_manager/services/site_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:flutter/services.dart';

void main() async {
  // 1. Initialize Flutter engine bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Lock orientation to portrait (Professional standard for inventory apps)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    // 3. Initialize Firebase 
    // If this fails it's usually the SHA-1/google-services.json
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 4. Ensure DB structure exists
    final siteService = SiteService();
    await siteService.ensureDefaultSitesExist();
  } catch (e) {
    debugPrint("Initialization Error: $e");
    // We continue to runApp so the app doesn't stay stuck on the splash screen
  }

  // 5. System UI Mode immersive to hide nav buttons and status bar
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flags Manager',
      theme: ThemeData(
        // Matching your orange aesthetic from previous screens
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6F00),
          primary: const Color(0xFFFF6F00),
        ),
        useMaterial3: true,
        // High-quality typography settings
        fontFamily: 'Roboto', 
      ),
      home: const AuthGate(),
    );
  }
}