import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(
                "App Overview & Statistics",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // স্ট্যাটাস কার্ডগুলো গ্রিড ভিউতে দেখানো হচ্ছে
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: "Total Users",
                    icon: Icons.people_alt_outlined,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  ),
                  _buildStatCard(
                    title: "Total Techs",
                    icon: Icons.handyman_outlined,
                    color: Colors.purple,
                    stream: FirebaseFirestore.instance.collection('technicians').where('status', isEqualTo: 'approved').snapshots(),
                  ),
                  _buildStatCard(
                    title: "Pending Requests",
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    stream: FirebaseFirestore.instance.collection('technicians').where('status', isEqualTo: 'pending').snapshots(),
                  ),
                  _buildStatCard(
                    title: "Total Bookings",
                    icon: Icons.book_online_outlined,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // এক্সট্রা ইনফো কার্ড
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC65C).withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFFFC65C)),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "Go to 'Technicians' tab to accept or reject new requests.",
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ✅ ডায়নামিক কাউন্ট কার্ড তৈরির উইজেট
  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // ডাটা থাকলে লেংথ নেবে, না থাকলে 0 দেখাবে
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }
}