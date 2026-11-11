
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmogRiskApp());
}

class SmogRiskApp extends StatelessWidget {
  const SmogRiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smog Risk Prediction System',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061321),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF091A2B),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 24,
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
