import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaticInfoScreen extends StatelessWidget {
  final String docId; // 'about_us' or 'privacy_policy'
  final String title;
  final IconData icon;

  const StaticInfoScreen({
    super.key,
    required this.docId,
    required this.title,
    required this.icon,
  });

  // ফলব্যাক ডাটা (যদি ফায়ারস্টোরে কোনো ডাটা না থাকে তাহলে এটি দেখাবে)
  String get _fallbackText {
    if (docId == 'about_us') {
      return "Sheba Finder BD is Bangladesh's leading home service platform. We connect you with verified, skilled technicians for your everyday needs — from electrical and plumbing work to cleaning and painting. Our mission is to make professional home services accessible, reliable, and hassle-free for everyone. \n\nFounded in 2024, our team is dedicated to bringing trust and transparency to the home service industry. Every technician on our platform goes through a strict verification process to ensure your safety and satisfaction.";
    } else {
      return "At Sheba Finder BD, your privacy is our top priority. This Privacy Policy explains how we collect, use, and protect your personal information when you use our application.\n\n1. Information We Collect:\nWe collect your name, email address, phone number, and service location when you register or book a service.\n\n2. How We Use Your Information:\nYour information is used solely to connect you with technicians, process bookings, and improve your app experience. We never sell your data to third parties.\n\n3. Data Security:\nWe use industry-standard encryption and secure servers to protect your data from unauthorized access.\n\nFor any privacy-related queries, please contact us at shebafinderbd@gmail.com.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('app_settings').doc(docId).get(),
        builder: (context, snapshot) {
          // ডাটা লোড হচ্ছে
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
          }

          // ডাটা নির্ধারণ করা (থাকলে ফায়ারস্টোর থেকে, না থাকলে ফলব্যাক থেকে)
          String displayText = _fallbackText;
          if (snapshot.hasData && snapshot.data!.exists) {
            displayText = snapshot.data!['content'] ?? _fallbackText;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // উপরে একটি সুন্দর আইকন কার্ড
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC65C).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFFFFC65C), size: 40),
                  ),
                ),
                const SizedBox(height: 30),

                // মেইন টেক্সট
                Text(
                  displayText,
                  textAlign: TextAlign.justify, // ✅ প্রফেশনাল জাস্টিফাইড টেক্সট
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.7, // লাইন স্পেসিং
                    letterSpacing: 0.3, // লেটার স্পেসিং
                  ),
                ),

                const SizedBox(height: 40),

                // নিচে কপিরাইট ইনফো
                const Center(
                  child: Text(
                    "© 2024 Sheba Finder BD. All rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }
}