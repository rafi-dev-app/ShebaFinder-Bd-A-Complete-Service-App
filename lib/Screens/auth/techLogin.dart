import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_home.dart';
import 'package:shebafinderbdnew/Screens/RoleSelection.dart';

class TechnicianLoginScreen extends StatefulWidget {
  const TechnicianLoginScreen({super.key});

  @override
  State<TechnicianLoginScreen> createState() => _TechnicianLoginScreenState();
}

class _TechnicianLoginScreenState extends State<TechnicianLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;


  void _loginTechnician() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();


    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Please enter a valid email", Colors.redAccent);
      return;
    }
    if (password.isEmpty) {
      _showSnackBar("Please enter your password", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      var techDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(userCredential.user!.uid)
          .get();

      if (techDoc.exists) {
        String status = techDoc.data()?['status'] ?? 'pending';

        if (status == 'approved') {

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => TechnicianHomeScreen()),
                  (route) => false,
            );
          }
        } else {

          await FirebaseAuth.instance.signOut();
          _showErrorDialog("Access Denied", "Your profile is still under review. Admin will approve it soon.");
        }
      } else {

        await FirebaseAuth.instance.signOut();
        _showSnackBar("No Technician account found with this email.", Colors.redAccent);
      }

    } on FirebaseAuthException catch (e) {
      String msg = "Login Failed";
      if (e.code == 'user-not-found') {
        msg = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        msg = "Incorrect password. Please try again.";
      } else {
        msg = e.message ?? "An error occurred.";
      }
      if (mounted) _showSnackBar(msg, Colors.redAccent);
    } catch (e) {
      if (mounted) _showSnackBar("Something went wrong!", Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.redAccent)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFC65C))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Technician Login",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              ),
              const SizedBox(height: 10),
              const Text("Welcome back! Manage your services.", style: TextStyle(color: Colors.white54, fontSize: 16)),

              const SizedBox(height: 50),


              _buildTextField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),

              _buildTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isObscure: !isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _loginTechnician,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC65C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2)
                      : const Text(
                    "Login",
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: Color(0xFFFFC65C), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFFFC65C)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFFFC65C), width: 1)
            ),
          ),
        ),
      ],
    );
  }
}