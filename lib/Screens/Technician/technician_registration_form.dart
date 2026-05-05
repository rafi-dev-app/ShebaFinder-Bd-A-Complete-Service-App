import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_home.dart';

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

  String selectedCategory = "Electrician"; // ডিফল্ট ক্যাটাগরি
  bool isLoading = false;

  // Image select ar Base64 string er jonno state
  File? _selectedImage;
  String? _base64Image;

  // ক্যাটাগরির লিস্ট
  final List<String> categories = [
    "Electrician", "Plumber", "Carpenter", "Painter", "AC Technician", "Cleaner"
  ];

  // Image Gallery theke neyar function
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

      // FIREBASE 1MB LIMIT CHECK: 900KB er beshi hole image nibona
      if (imageBytes.length > 900000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image is too large! Please select a smaller image."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String base64String = base64Encode(imageBytes);

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64String;
      });
    }
  }

  void _submitRegistration() async {
    // Validation: Name ar Phone must dite hobe
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill up Name and Phone Number"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ফায়ারবেস ডেটাবেসে 'technicians' নামের কালেকশনে ডেটা পাঠানো হচ্ছে
      await FirebaseFirestore.instance.collection('technicians').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'category': selectedCategory,
        'experience': _experienceController.text.trim(),
        'imageBase64': _base64Image, // <--- EITA ADD KORLAM (Image string)
        'totalRatingSum': 0.0,
        'ratingCount': 0,
        'isAvailable': false,
        'appliedAt': DateTime.now().toIso8601String(),
        'status': 'pending', // <--- DUPLICATE STATUS REMOVE KORLAM
      });


      if (mounted) {
        // ডেটাবেসে গেছে, এখন সাকসেস মেসেজ দেখাও
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle, color: Color(0xFFFFC65C), size: 60),
            content: const Text(
              "Application Submitted!\n\nWe will review your profile. Once approved, you can log in.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog close
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TechnicianHomeScreen()), // Ei page e niye jabe
                  );
                },
                child: const Text("OK", style: TextStyle(color: Color(0xFFFFC65C), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      // যদি কোনো এরর হয় (যেমন ইন্টারনেট না থাকলে)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
        title: const Text("Technician Registration", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Join Our Team", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Fill up your professional details", style: TextStyle(color: Colors.white54)),

            const SizedBox(height: 30),

            // --- IMAGE PICKER UI ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFC65C), width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Color(0xFFFFC65C), size: 40),
                      SizedBox(height: 5),
                      Text("Add Photo", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // --- END OF IMAGE PICKER ---

            _buildTextField("Full Name", Icons.person_outline, _nameController),
            const SizedBox(height: 20),
            _buildTextField("Phone Number", Icons.phone_outlined, _phoneController),
            const SizedBox(height: 20),
            _buildTextField("Shop / Living Address", Icons.location_on_outlined, _addressController),
            const SizedBox(height: 20),

            // ক্যাটাগরি ড্রপডাউন
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Service Category", style: TextStyle(color: Color(0xFFFFC65C), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      items: categories.map((String item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildTextField("Experience (e.g., 3 Years)", Icons.work_history_outlined, _experienceController),

            const SizedBox(height: 40),

            // সাবমিট বাটন
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
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: Color(0xFFFFC65C), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $hint",
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: const Color(0xFFFFC65C)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}