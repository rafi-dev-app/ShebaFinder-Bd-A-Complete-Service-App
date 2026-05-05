import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shebafinderbdnew/Screens/RoleSelection.dart';

class TechProfile extends StatelessWidget {
  const TechProfile({super.key});

  // ================= LOGOUT FUNCTION =================
  Future<void> _logout(BuildContext context) async {
    // কনফার্মেশন ডায়ালগ
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
              (route) => false,
        );
      }
    }
  }

  // ================= EDIT PROFILE DIALOG =================
  void _showEditDialog(BuildContext context, String currentName, String currentBase64) {
    TextEditingController nameController = TextEditingController(text: currentName);
    String dialogImageBase64 = currentBase64;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
                      if (image != null) {
                        File file = File(image.path);
                        List<int> bytes = await file.readAsBytes();
                        setDialogState(() {
                          dialogImageBase64 = base64Encode(bytes);
                        });
                      }
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: dialogImageBase64.isNotEmpty ? MemoryImage(base64Decode(dialogImageBase64)) : null,
                          child: dialogImageBase64.isEmpty ? const Icon(Icons.camera_alt, color: Colors.white54, size: 30) : null,
                        ),
                        const SizedBox(height: 8),
                        const Text("Tap to change photo", style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFC65C))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    await FirebaseFirestore.instance
                        .collection('technicians')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({
                      'name': nameController.text.trim(),
                      'imageBase64': dialogImageBase64,
                    });

                    if (context.mounted) Navigator.pop(context);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC65C)),
                  child: const Text("Save", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('technicians').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No Data Found", style: TextStyle(color: Colors.white54)));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? "No Name";
          String category = data['category'] ?? "Technician";
          String experience = data['experience'] ?? "0 Years";
          String? base64Image = data['imageBase64'];
          String status = data['status'] ?? 'pending'; // Admin er dewa status

          // Rating Calculation
          double totalSum = (data['totalRatingSum'] ?? 0.0).toDouble();
          int count = (data['ratingCount'] ?? 0).toInt();
          double avgRating = count > 0 ? (totalSum / count) : 0.0;

          // Status Color Logic
          Color statusColor = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ================= TOP PROFILE SECTION =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      // Profile Image
                      GestureDetector(
                        onTap: () => _showEditDialog(context, name, base64Image ?? ''),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFC65C), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: (base64Image != null && base64Image.isNotEmpty) ? MemoryImage(base64Decode(base64Image)) : null,
                            child: (base64Image == null || base64Image.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.white24) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Name & Category
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(category, style: const TextStyle(color: Colors.white54, fontSize: 14)),

                      const SizedBox(height: 15),

                      // ✅ Admin Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status == 'approved' ? Icons.verified : Icons.hourglass_top, color: statusColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Edit Profile Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton(
                          onPressed: () => _showEditDialog(context, name, base64Image ?? ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC65C),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= STATS CARDS =================
                Row(
                  children: [
                    _buildStatCard(Icons.work_history_outlined, "Experience", experience, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.star_rounded, "Rating", avgRating.toStringAsFixed(1), Colors.orange),
                  ],
                ),

                const SizedBox(height: 25),

                // ================= MENU OPTIONS =================
                _buildProfileOption(context, Icons.share_outlined, "Share My Profile", onTap: () {
                  // ভবিষ্যতে এখানে শেয়ার লিংকের লজিক বসাতে পারো
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Share feature coming soon!"), backgroundColor: Color(0xFFFFC65C)));
                }),
                _buildProfileOption(context, Icons.lock_outline, "Change Password", onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password change coming soon!"), backgroundColor: Color(0xFFFFC65C)));
                }),
                _buildProfileOption(context, Icons.help_outline, "Help & Support", onTap: () {}),
                _buildProfileOption(context, Icons.info_outline, "About App", onTap: () {}),

                const SizedBox(height: 30),

                // ================= LOGOUT BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= HELPER WIDGETS =================

  // Stats Card Widget
  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Menu Option Widget
  Widget _buildProfileOption(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFC65C), size: 22),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: const Color(0xFF1E293B),
      ),
    );
  }
}