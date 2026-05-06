import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ যোগ করা হয়েছে
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/RoleSelection.dart'; // ✅ যোগ করা হয়েছে

class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  // ✅ লগআউট করার ফাংশন
  Future<void> _logout(BuildContext context) async {
    // কনফার্মেশন ডায়ালগ দেখানো হচ্ছে
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout from Admin Panel?", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // যদি ইউজার কনফার্ম করে
    if (confirm == true) {
      await FirebaseAuth.instance.signOut(); // Firebase থেকে সাইনআউট
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), // রোল সিলেকশনে নিয়ে যাওয়া হচ্ছে
              (route) => false, // ব্যাক বাটন প্রেস করে আবার অ্যাডমিনে আসা বন্ধ করা হচ্ছে
        );
      }
    }
  }

  // ✅ টেক্সট আপডেট করার ডায়ালগ
  void _showUpdateDialog(BuildContext context, String docId, String currentText) {
    TextEditingController controller = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == 'about_us' ? "Update About Us" : "Update Privacy Policy", style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFC65C))),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('app_settings').doc(docId).set({
                    'content': controller.text.trim(),
                  }, SetOptions(merge: true));

                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated Successfully!"), backgroundColor: Colors.green));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC65C)),
              child: const Text("Save", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SizedBox(height: 20),
        const Text("App Settings", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Manage app content without updating the app.", style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 30),

        _buildSettingsCard(
          context: context,
          title: "About Us Content",
          subtitle: "Change the About Us page text",
          icon: Icons.info,
          docId: 'about_us',
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context: context,
          title: "Privacy Policy Content",
          subtitle: "Change the Privacy Policy text",
          icon: Icons.privacy_tip,
          docId: 'privacy_policy',
        ),

        const SizedBox(height: 40),

        // ✅ ডিভাইডার দিয়ে আলাদা করা হয়েছে
        const Divider(color: Colors.white10, height: 20, indent: 10, endIndent: 10),

        // ✅ লগআউট বাটন যোগ করা হয়েছে
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            onTap: () => _logout(context),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.redAccent),
            ),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),


        ),
              const SizedBox(height: 40), // নিচ থেকে একটু জায়গা ফাঁকা রাখা হয়েছে
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required BuildContext context, required String title, required String subtitle, required IconData icon, required String docId}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('app_settings').doc(docId).get(),
      builder: (context, snapshot) {
        String preview = "Tap to add content";
        if (snapshot.hasData && snapshot.data!.exists) {
          String fullText = snapshot.data!['content'] ?? '';
          preview = fullText.length > 50 ? "${fullText.substring(0, 50)}..." : fullText;
        }

        return GestureDetector(
          onTap: () => _showUpdateDialog(context, docId, snapshot.hasData && snapshot.data!.exists ? snapshot.data!['content'] ?? '' : ''),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFC65C).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFFFFC65C))),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(preview, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }
}