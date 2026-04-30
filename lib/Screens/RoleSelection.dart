import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_registration_form.dart';
import 'package:shebafinderbdnew/Screens/auth/techLogin.dart';
import 'package:shebafinderbdnew/Screens/auth/UserLoginScreen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B264D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text(
              "Choose Your Path",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "What brings you here today?",
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  buildRoleCard(
                    context: context,
                    icon: Icons.person_outline,
                    title: "I am User",
                    description: "Looking to hire trusted professionals.",
                    buttonText: "Login as User",
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserLoginScreen()));
                    },
                  ),

                  const SizedBox(height: 20),


                  buildRoleCard(
                    context: context,
                    icon: Icons.handyman_outlined,
                    title: "Looking for a Job?",
                    description: "Join as a Technician & grow your business.",
                    buttonText: "Register Now",
                    isGold: true,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TechnicianRegistrationScreen()));
                    },

                    extraWidget: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ",
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicianLoginScreen()));
                            },
                            child: const Text(
                              "Login here",
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),


                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserLoginScreen(isAdmin: true)));
                    },
                    child: const Text(
                      "Admin Access",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }


  Widget buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    bool isGold = false,
    Widget? extraWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFFFC65C) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isGold ? const Color(0xFF0F172A).withValues(alpha: 0.1) : const Color(0xFFF0F2F8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: isGold ? const Color(0xFF0F172A) : const Color(0xFF1B264D)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isGold ? const Color(0xFF0F172A) : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isGold ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGold ? const Color(0xFF0F172A) : const Color(0xFF4A78DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(buttonText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),

            if (extraWidget != null) extraWidget,
          ],
        ),
      ),
    );
  }
}