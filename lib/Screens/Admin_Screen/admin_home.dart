import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Admin_Screen/admin_dashboard.dart';
import 'package:shebafinderbdnew/Screens/Admin_Screen/admin_setting.dart';
import 'package:shebafinderbdnew/Screens/Admin_Screen/admin_tech_management.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const AdminTechManagement(),
    const AdminSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFFFC65C),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people), label: "Technicians"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}