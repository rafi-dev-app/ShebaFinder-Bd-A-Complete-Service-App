
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/SplashScreen.dart';
void main() async {
  runApp(const ShebaFinderApp());
}

class ShebaFinderApp extends StatelessWidget {
  const ShebaFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sheba Finder BD',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
            primary: const Color(0xFFFFC65C),
            surface: const Color(0xFF1E293B)
        ),
        useMaterial3: true,
      ),
      home: const SplashScreens(),
    );
  }
}
