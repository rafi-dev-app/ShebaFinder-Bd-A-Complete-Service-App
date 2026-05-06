import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminTechManagement extends StatefulWidget {
  const AdminTechManagement({super.key});

  @override
  State<AdminTechManagement> createState() => _AdminTechManagementState();
}

class _AdminTechManagementState extends State<AdminTechManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ টেকনিশিয়ানকে Accept করার ফাংশন
  Future<void> _acceptTechnician(DocumentSnapshot doc) async {
    try {
      await doc.reference.update({'status': 'approved'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Technician Approved!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ টেকনিশিয়ানকে Reject করার ফাংশন
  Future<void> _rejectTechnician(DocumentSnapshot doc) async {
    // কনফার্মেশন ডায়ালগ
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reject Technician?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Reject", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      await doc.reference.update({'status': 'rejected'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Technicians", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFC65C),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFFC65C),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Pending Requests"),
            Tab(text: "Approved"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildApprovedList(),
        ],
      ),
    );
  }

  // ================= PENDING LIST =================
  // ================= PENDING LIST =================
  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technicians')
          .where('status', isEqualTo: 'pending')
      // ✅ .orderBy('appliedAt', descending: true) এই লাইনটি মুছে দেওয়া হয়েছে
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.white24),
                SizedBox(height: 15),
                Text("No pending requests", style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        // ✅ কোডে ম্যানুয়ালি সর্ট করা হচ্ছে (নতুনগুলো উপরে থাকবে)
        var allDocs = snapshot.data!.docs;
        allDocs.sort((a, b) {
          var timeA = a['appliedAt'];
          var timeB = b['appliedAt'];

          // যদি টাইমস্ট্যাম্প হয়
          if (timeA is Timestamp && timeB is Timestamp) {
            return timeB.toDate().compareTo(timeA.toDate()); // Descending order
          }

          // না হলে স্ট্রিং হিসেবে সর্ট করবে
          return (timeB.toString()).compareTo(timeA.toString());
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          // ✅ snapshot.data!.docs এর বদলে allDocs ব্যবহার করতে হবে
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            var doc = allDocs[index]; // ✅ এখানেও allDocs
            var data = doc.data() as Map<String, dynamic>;

            return _buildTechCard(doc, data, isPending: true);
          },
        );
      },
    );
  }

  // ================= APPROVED LIST =================
  Widget _buildApprovedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technicians')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No approved technicians yet", style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildTechCard(doc, data, isPending: false);
          },
        );
      },
    );
  }

  // ================= TECH CARD UI =================
  Widget _buildTechCard(DocumentSnapshot doc, Map<String, dynamic> data, {required bool isPending}) {
    String name = data['name'] ?? "Unknown";
    String category = data['category'] ?? "General";
    String phone = data['phone'] ?? "N/A";
    String experience = data['experience'] ?? "0 Years";

    // Image Decoding
    Uint8List? imageBytes;
    if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty) {
      try {
        imageBytes = base64Decode(data['imageBase64']);
      } catch (e) {
        // ছবি ক্রাশ করলে শুধু আইকন দেখাবে
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: isPending
            ? Border.all(color: Colors.orange.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: imageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                )
                    : const Icon(Icons.person, color: Colors.white54, size: 30),
              ),
              const SizedBox(width: 15),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text("$category • $experience", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("📞 $phone", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          // ✅ Accept / Reject Buttons (শুধু Pending এ দেখাবে)
          if (isPending) ...[
            const Divider(color: Colors.white10, height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptTechnician(doc),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Accept", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectTechnician(doc),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // ✅ correct
                        )
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}