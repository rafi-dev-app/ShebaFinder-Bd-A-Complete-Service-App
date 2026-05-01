import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // ✅ ইমেইল পাঠানোর ফাংশন
  // ✅ ইমেইল পাঠানোর ফাংশন
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'shebafinderbd@gmail.com',
      queryParameters: {
        'subject': 'Support Request - Sheba Finder BD App',
        'body': 'Hello Sheba Finder Support Team',
      },
    );

    try {
      if (!await launchUrl(emailUri)) {
        debugPrint('Could not launch email');
      }
    } catch (e) {
      debugPrint('Email Error: $e');
    }
  }

  // ✅ কল করার ফাংশন
  Future<void> _launchCall() async {
    final Uri callUri = Uri(scheme: 'tel', path: '01912345678');

    try {
      if (!await launchUrl(callUri)) {
        debugPrint('Could not launch call');
      }
    } catch (e) {
      debugPrint('Call Error: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Help & Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // উপরের আইকন
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC65C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headset_mic, color: Color(0xFFFFC65C), size: 60),
            ),

            const SizedBox(height: 25),
            const Text(
              "How can we help you?",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose an option below to reach out to us.\nWe are always ready to assist you.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 40),

            // ================= EMAIL US BUTTON =================
            GestureDetector(
              onTap: _launchEmail,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC65C).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.email_outlined, color: Color(0xFFFFC65C), size: 30),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email Us", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("shebafinderbd@gmail.com", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= CALL US BUTTON =================
            GestureDetector(
              onTap: _launchCall,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_in_talk_outlined, color: Colors.green, size: 30),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Call Us", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("01912345678", style: TextStyle(color: Colors.white54, fontSize: 13)), // এখানে তোমার নম্বর দাও
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ================= এক্সট্রা: FAQ বা অন্য কিছু থাকলে নিচে দেওয়া যাবে =================
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Our support team is available from Sat to Thu, 9:00 AM to 9:00 PM.",
                      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}