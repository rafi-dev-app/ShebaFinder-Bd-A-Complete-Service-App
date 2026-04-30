import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shebafinderbdnew/Screens/RoleSelection.dart';

class TechnicianRegistrationScreen extends StatefulWidget {
  const TechnicianRegistrationScreen({super.key});

  @override
  State<TechnicianRegistrationScreen> createState() => _TechnicianRegistrationScreenState();
}

class _TechnicianRegistrationScreenState extends State<TechnicianRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // নতুন কন্ট্রোলার

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String selectedCategory = "Electrician";
  bool isLoading = false;

  File? _selectedImage;
  String? _base64Image;

  final List<String> categories = [
    "Electrician", "Plumber", "Carpenter", "Painter", "AC Technician", "Cleaner"
  ];

  // ✅ অ্যাডভান্স ইমেইল চেকার ফাংশন (ফেক ডোমেইন ব্লক সহ)
  bool _isValidEmail(String email) {
    // ১. প্রথমে সাধারণ ফরম্যাট ঠিক আছে কি না চেক করা হচ্ছে
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) return false;

    // ২. ডোমেইন আলাদা করা হচ্ছে (যেমন: rafi@gmail.com থেকে gmail.com আলাদা করা হবে)
    String domain = email.split('@').last.toLowerCase();

    // ৩. যেসব ফেক/টেস্টিং ডোমেইনগুলোর একটি লিস্ট (তুমি চাইলে এখানে আরো যোগ করতে পারো)
    List<String> blockedDomains = [
      'test.com', 'example.com', 'mailinator.com', 'guerrillamail.com',
      'fake.com', 'yopmail.com', 'tempmail.com', 'throwaway.email',
      '10minutemail.com', 'sharklasers.com', 'guerrillamailblock.com'
    ];

    // ৪. যদি ইউজার এই ব্লককৃত ডোমেইনগুলোর কোনো একটি ব্যবহার করে, তাহলে সাইনআপ বন্ধ করে দেওয়া হবে
    if (blockedDomains.contains(domain)) {
      return false;
    }

    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 15,
      maxWidth: 200.0,
      maxHeight: 200.0,
    );

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();

      if (imageBytes.length > 900000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image is too large! Max 900KB allowed."), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64Encode(imageBytes);
      });
    }
  }

  void _submitRegistration() async {
    // ভ্যালিডেশন
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showSnackBar("Please fill all required fields", Colors.redAccent);
      return;
    }
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showSnackBar("Passwords do not match!", Colors.redAccent); // পাসওয়ার্ড ম্যাচিং চেক
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.redAccent);
      return;
    }
    // ✅ অ্যাডমিন ইমেইল দিয়ে কেউ সাইনআপ করতে পারবে কি না তা ব্লক করা হচ্ছে
    if (_emailController.text.trim().toLowerCase() == 'admin@gmail.com') {
      _showSnackBar("This email is restricted. Please use a different email.", Colors.redAccent);
      return;
    }

    if (_emailController.text.trim().isEmpty || !_isValidEmail(_emailController.text.trim())) {
      _showSnackBar("Please enter a valid email address", Colors.redAccent);
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Please enter your name", Colors.redAccent);
      return;
    }

    // ✅ অ্যাডমিন ইমেইল দিয়ে কেউ সাইনআপ করতে পারবে কি না তা ব্লক করা হচ্ছে
    if (_emailController.text.trim().toLowerCase() == 'admin@gmail.com') {
      _showSnackBar("This email is restricted. Please use a different email.", Colors.redAccent);
      return;
    }

    if (_emailController.text.trim().isEmpty || !_isValidEmail(_emailController.text.trim())) {
      _showSnackBar("Please enter a valid email address", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );


      await FirebaseFirestore.instance.collection('technicians').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'category': selectedCategory,
        'experience': _experienceController.text.trim(),
        'imageBase64': _base64Image,
        'totalRatingSum': 0.0,
        'ratingCount': 0,
        'isAvailable': false,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // ✅ ইমেইল ভেরিফিকেশন লিংক পাঠানো হচ্ছে
      await userCredential.user?.sendEmailVerification();

      await FirebaseAuth.instance.signOut();

      if (mounted) _showSuccessDialog();

      await FirebaseAuth.instance.signOut();

      if (mounted) _showSuccessDialog();

    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Registration Failed";
      _showSnackBar(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Color(0xFFFFC65C), size: 60),
        content: const Text(
          "Registration Successful!\n\nAdmin will review your profile. Once approved, you can login.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    (route) => false,
              );
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFC65C), fontWeight: FontWeight.bold)),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Join Our Team", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Fill up your professional details", style: TextStyle(color: Colors.white54)),

            const SizedBox(height: 30),

            // --- IMAGE PICKER UI ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1E293B),
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.camera_alt, color: Color(0xFFFFC65C), size: 40)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 30),

            _buildTextField("Full Name", Icons.person_outline, _nameController),
            const SizedBox(height: 20),
            _buildTextField("Phone Number", Icons.phone_outlined, _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildTextField("Address", Icons.location_on_outlined, _addressController),
            const SizedBox(height: 20),
            _buildTextField("Email Address", Icons.email_outlined, _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              "Password",
              Icons.lock_outline,
              _passwordController,
              isObscure: !isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white38),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password Field
            _buildTextField(
              "Confirm Password",
              Icons.lock_reset,
              _confirmPasswordController,
              isObscure: !isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white38),
                onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Service Category", style: TextStyle(color: Color(0xFFFFC65C), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => selectedCategory = val!),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildTextField("Experience (e.g. 3 Years)", Icons.work_history_outlined, _experienceController),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC65C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF0F172A))
                    : const Text("Submit Application", style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isObscure = false, Widget? suffixIcon, TextInputType? keyboardType}) {
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFFFC65C), width: 1)),
          ),
        ),
      ],
    );
  }
}