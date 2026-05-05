import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Technician/fragments/Booking_fragments.dart';
import 'package:shebafinderbdnew/Screens/Technician/fragments/Earning_fragments.dart';
import 'package:shebafinderbdnew/Screens/Technician/fragments/profile_fragments.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TechDashboardFragment(),
    const TechBookings(),
    const TechEarnings(),
    const TechProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFFFC65C),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work_outlined),
            activeIcon: Icon(Icons.home_work),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Earnings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class TechDashboardFragment extends StatelessWidget {
  const TechDashboardFragment({super.key});

  Future<void> _toggleStatus(String uid, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('technicians').doc(uid).update({
      'isAvailable': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null)
      return const Center(
        child: Text("Login Required", style: TextStyle(color: Colors.white)),
      );

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFC65C)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text("No Data Found", style: TextStyle(color: Colors.white)),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool isAvailable = data['isAvailable'] ?? false;
        String techName = data['name'] ?? "Technician";

        // ✅ রেটিং হিসাব করা হচ্ছে (ডায়নামিক নয়)
        double totalSum = (data['totalRatingSum'] ?? 0.0).toDouble();
        int count = (data['ratingCount'] ?? 0).toInt();
        String avgRating = count > 0
            ? (totalSum / count).toStringAsFixed(1)
            : "0.0";

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back,",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            techName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildNotificationIcon(),
                  ],
                ),

                const SizedBox(height: 25),

                // --- Status Card (Firebase Toggle) ---
                _buildStatusToggle(uid, isAvailable),

                const SizedBox(height: 30),

                // --- Quick Stats (Fully Dynamic) ---
                Row(
                  children: [
                    // ✅ নতুন জব গুলো রিয়েল টাইমে আনছে
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('techDocId', isEqualTo: uid)
                            .where('status', isEqualTo: 'Pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return _buildQuickStat(
                            Icons.pending_actions,
                            "New Jobs",
                            count.toString(),
                            Colors.blue,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ কাজ শেষ হওয়া গুলো রিয়েল টাইমে আনছে
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bookings')
                            .where('techDocId', isEqualTo: uid)
                            .where('status', isEqualTo: 'Completed')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return _buildQuickStat(
                            Icons.check_circle_outline,
                            "Completed",
                            count.toString(),
                            Colors.green,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ রেটিং আগে থেকেই ক্যালকুলেটেড
                    Expanded(
                      child: _buildQuickStat(
                        Icons.star_outline,
                        "Rating",
                        avgRating,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- Recent Bookings (Fully Dynamic) ---
                const Text(
                  "Recent Bookings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // ✅ বুকিংস লিস্ট রিয়েল টাইমে আনা হচ্ছে
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('techDocId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFC65C),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text(
                            "No bookings yet",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    // ম্যানুয়ালি সর্ট করা হচ্ছে (Index Error এড়াও এড়াতে)
                    var allDocs = snapshot.data!.docs;
                    allDocs.sort((a, b) {
                      var timeA = a['bookingTime'] ?? '';
                      var timeB = b['bookingTime'] ?? '';
                      if (timeA is Timestamp && timeB is Timestamp) {
                        return timeB.toDate().compareTo(timeA.toDate());
                      }
                      return timeB.toString().compareTo(timeA.toString());
                    });

                    // সর্বোচ্চ ২টি বুকিং দেখাবে
                    var recentDocs = allDocs.take(2).toList();

                    return Column(
                      children: recentDocs.map((doc) {
                        var bookingData = doc.data() as Map<String, dynamic>;

                        String name = bookingData['userName'] ?? "Unknown User";
                        String service =
                            bookingData['techCategory'] ?? "Service";
                        String status = bookingData['status'] ?? "Pending";

                        // স্ট্যাটাস অনুযায়ী রং নির্ধারণ
                        Color statusColor;
                        if (status == 'Pending')
                          statusColor = Colors.orange;
                        else if (status == 'Accepted')
                          statusColor = Colors.blue;
                        else if (status == 'Paid')
                          statusColor = Colors.teal;
                        else
                          statusColor = Colors.green;

                        return _buildBookingItem(
                          name,
                          service,
                          status,
                          statusColor,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Widgets (UI একদম আগের মতোই আছে) ---

  Widget _buildStatusToggle(String uid, bool isAvailable) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [const Color(0xFFFFC65C), Colors.orange]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Status",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                isAvailable ? "Available Now" : "Currently Busy",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            activeColor: Colors.greenAccent,
            onChanged: (val) => _toggleStatus(uid, isAvailable),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.notifications_none, color: Color(0xFFFFC65C)),
    );
  }

  Widget _buildQuickStat(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(
    String name,
    String service,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.white54),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  service,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
