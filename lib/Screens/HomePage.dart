import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ নতুন যোগ করা হয়েছে
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_details.dart';
import 'package:shebafinderbdnew/Screens/categories_technician.dart';
import 'package:shebafinderbdnew/Screens/Fragments_Home/booking_list.dart';
import 'package:shebafinderbdnew/Screens/Fragments_Home/Profile_Tab.dart';
import 'package:shebafinderbdnew/Screens/Fragments_Home/support_Tab.dart';
import 'package:shebafinderbdnew/Screens/user/Search_Screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const _MainDashboard(),
    const BookingListScreen(),
    const SupportScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFFFFC65C),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.headset_mic_outlined), label: "Support"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class _MainDashboard extends StatelessWidget {
  const _MainDashboard();

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ==================== HEADER SECTION ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ ১. ডাইনামিক লোকেশন
                  Expanded(
                    child: uid != null
                        ? StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('addresses')
                          .orderBy('createdAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String displayAddress = "Set Location";
                        String displayLabel = "Current Location";

                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          var addrData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                          displayAddress = addrData['address'] ?? "Unknown";
                          displayLabel = addrData['label'] ?? "Location";

                          if (displayAddress.length > 25) {
                            displayAddress = "${displayAddress.substring(0, 25)}...";
                          }
                        }

                        return Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.orange),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  Text(displayAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    )
                        : const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.orange),
                        SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Current Location", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text("Login Required", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ✅ ২. ডাইনামিক প্রোফাইল আইকন
                  GestureDetector(
                    onTap: () {
                      // ক্লিক করলে সরাসরি প্রোফাইল ট্যাবে নিয়ে যাবে
                      if (context.mounted) {
                        final _HomeScreenState? homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        if (homeState != null) {
                          homeState.setState(() {
                            homeState._currentIndex = 3; // 3 হলো Profile Tab এর ইনডেক্স
                          });
                        }
                      }
                    },
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                      builder: (context, snapshot) {
                        Uint8List? profileBytes;
                        bool hasImage = false;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          var data = snapshot.data!.data() as Map<String, dynamic>;
                          String base64Img = data['imageBase64'] ?? '';
                          if (base64Img.isNotEmpty) {
                            try {
                              profileBytes = base64Decode(base64Img);
                              hasImage = true;
                            } catch (e) {}
                          }
                        }

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFC65C), width: 2), // সুন্দর একটা বর্ডার দেওয়া হয়েছে
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFF1E293B),
                            child: hasImage && profileBytes != null
                                ? ClipOval(child: Image.memory(profileBytes, fit: BoxFit.cover, width: 44, height: 44))
                                : const Icon(Icons.person, color: Colors.white54, size: 24),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ==================== SEARCH SECTION ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search services...",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFC65C)),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFFC65C), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.tune, color: Color(0xFF0F172A), size: 18),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ==================== CATEGORIES SECTION ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Categories", style: TextStyle(color: Colors.white, fontSize: 18)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCategoriesScreen()));
                    },
                    child: const Row(
                      children: [
                        Text("See All", style: TextStyle(color: Color(0xFFFFC65C), fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios, color: Color(0xFFFFC65C), size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ==================== HORIZONTAL SCROLLABLE CATEGORIES ====================
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _categoryItem(Icons.electric_bolt, "Electrician", context),
                  _categoryItem(Icons.plumbing, "Plumber", context),
                  _categoryItem(Icons.chair, "Carpenter", context),
                  _categoryItem(Icons.format_paint, "Painter", context),
                  _categoryItem(Icons.cleaning_services, "Cleaner", context),
                  _categoryItem(Icons.build, "Mestory", context),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ==================== TECHNICIANS SECTION HEADER ====================
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Top Rated Technicians", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ==================== TECHNICIANS LIST ====================
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('technicians').where('status', isEqualTo: 'approved').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C))));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("No technicians found", style: TextStyle(color: Colors.white54))),
                  ),
                );
              }

              var allDocs = snapshot.data!.docs;

              var ratedDocs = allDocs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                double totalSum = (data['totalRatingSum'] ?? 0.0).toDouble();
                int count = (data['ratingCount'] ?? 0).toInt();
                double avgRating = count > 0 ? (totalSum / count) : 0.0;
                return avgRating > 0.0;
              }).toList();

              ratedDocs.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                double avgA = (dataA['totalRatingSum'] ?? 0.0).toDouble() / ((dataA['ratingCount'] ?? 1).toInt());
                double avgB = (dataB['totalRatingSum'] ?? 0.0).toDouble() / ((dataB['ratingCount'] ?? 1).toInt());
                return avgB.compareTo(avgA);
              });

              if (ratedDocs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("No rated technicians yet", style: TextStyle(color: Colors.white54))),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var doc = ratedDocs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      double totalRatingSum = (data['totalRatingSum'] ?? 0.0).toDouble();
                      int ratingCount = (data['ratingCount'] ?? 0).toInt();
                      double averageRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;

                      Uint8List? imageBytes;
                      if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty) {
                        imageBytes = base64Decode(data['imageBase64']);
                      }

                      return _technicianCard(context, data, doc.id, imageBytes);
                    },
                    childCount: ratedDocs.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ==================== CATEGORY ITEM WIDGET ====================
Widget _categoryItem(IconData icon, String label, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryTechnicianScreen(categoryName: label)));
    },
    child: Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.orange),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ==================== TECHNICIAN CARD WIDGET ====================
Widget _technicianCard(BuildContext context, Map<String, dynamic> data, String docId, Uint8List? imageBytes) {
  String name = data['name'] ?? "Unknown";
  String category = data['category'] ?? "General";
  double totalRatingSum = (data['totalRatingSum'] ?? 0.0).toDouble();
  int ratingCount = (data['ratingCount'] ?? 0).toInt();
  double averageRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;
  bool isAvailable = data['isAvailable'] ?? false;

  return InkWell(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianDetailScreen(docId: docId)));
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(15)),
            child: imageBytes != null
                ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(imageBytes, fit: BoxFit.cover))
                : const Icon(Icons.person, color: Colors.white54, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 14),
                          SizedBox(width: 3),
                          Text("Verified", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(category, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(averageRating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAvailable ? "Available" : "Busy",
                        style: TextStyle(color: isAvailable ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ],
      ),
    ),
  );
}

// ==================== NEW: ALL CATEGORIES SCREEN ====================
class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  final List<Map<String, IconData>> allCategories = const [
    {'Electrician': Icons.electric_bolt},
    {'Plumber': Icons.plumbing},
    {'Carpenter': Icons.chair},
    {'Painter': Icons.format_paint},
    {'Cleaner': Icons.cleaning_services},
    {'Mestory': Icons.build},
    {'AC Tech': Icons.ac_unit},
    {'Locksmith': Icons.lock},
    {'Interior': Icons.design_services},
    {'Pest Control': Icons.bug_report},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text("All Categories", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
          itemCount: allCategories.length,
          itemBuilder: (context, index) {
            String title = allCategories[index].keys.first;
            IconData icon = allCategories[index].values.first;

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryTechnicianScreen(categoryName: title)));
              },
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.orange, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}