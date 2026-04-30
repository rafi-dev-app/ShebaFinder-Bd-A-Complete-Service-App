import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shebafinderbdnew/Screens/OnboardingScreen.dart';


class SplashScreens extends StatefulWidget {
  const SplashScreens({super.key});

  @override
  State<SplashScreens> createState() => _SplashScreensState();
}

class _SplashScreensState extends State<SplashScreens> {
  @override
  void initState() {
    super.initState();
    _moveToNextScreen();
  }

  Future<void> _moveToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset("Assets/animations/Electrician.json"),
                const SizedBox(height: 20),
                const Text(
                  "SHEBA FINDER BD",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101D42),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "HOME SERVICE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            left: 50,
            right: 50,
            child: const SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFF0F2F8),
                color: Color(0xFF101D42),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}