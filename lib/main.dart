import 'package:ecoflown/startpage/Homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // add this import

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optional: ensure SharedPreferences can be accessed before running app
  try {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("SharedPreferences initialized: ${prefs.getKeys()}");
  } catch (e) {
    debugPrint("SharedPreferences initialization failed: $e");
  }

  runApp(const EcoFlowApp());
}

class EcoFlowApp extends StatelessWidget {
  const EcoFlowApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoFlow',
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // replace with Onboarding later
    );
  }
}
