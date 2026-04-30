
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shebafinderbdnew/Screens/HomePage.dart';
import 'package:shebafinderbdnew/Screens/SplashScreen.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_home.dart';
import 'package:shebafinderbdnew/Screens/Admin_Screen/admin_home.dart';
import 'package:shebafinderbdnew/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});


  Future<String> _getUserRole(String uid, String? email) async {
    try {

      if (email == 'admin@gmail.com') {
        return "admin";
      }


      var techDoc = await FirebaseFirestore.instance.collection('technicians').doc(uid).get();
      if (techDoc.exists) return "technician";

      return "user";
    } catch (e) {
      return "user";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C))),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String>(

            future: _getUserRole(snapshot.data!.uid, snapshot.data!.email),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C))),
                );
              }

              if (roleSnapshot.data == "technician") {
                return const TechnicianHomeScreen();
              } else if (roleSnapshot.data == "admin") {

                return const AdminHomeScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }

        else {
          return const SplashScreens();
        }
      },
    );
  }
}