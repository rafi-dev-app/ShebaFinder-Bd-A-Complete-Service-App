import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TechBookings extends StatelessWidget {
  const TechBookings({super.key});

  @override
  Widget build(BuildContext context) {
    final String? techUid = FirebaseAuth.instance.currentUser?.uid;

    if (techUid == null) {
      return const Center(child: Text("Login Required", style: TextStyle(color: Colors.white54)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('techDocId', isEqualTo: techUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No booking requests yet", style: TextStyle(color: Colors.white54)));
          }

          var allDocs = snapshot.data!.docs;
          allDocs.sort((a, b) => (b['bookingTime'] ?? '').compareTo(a['bookingTime'] ?? ''));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allDocs.length,
            itemBuilder: (context, index) {
              var doc = allDocs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String currentStatus = data['status'] ?? "Pending";

              // রং নির্ধারণ
              Color statusColor = currentStatus == 'Pending' ? Colors.orange :
              currentStatus == 'Accepted' ? Colors.blue :
              Colors.green; // Completed

              // যদি ইউজার পেমেন্ট করে ফেলে (Paid) টেকনিশিয়ানকে Completed দেখাবে
              String displayStatus = currentStatus == 'Paid' ? 'Completed' : currentStatus;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentStatus == "Pending" ? Colors.orange.withOpacity(0.3) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(data['userName'] ?? "Unknown User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        if(currentStatus == "Pending")
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text("New Request", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("📞 ${data['userPhone'] ?? 'N/A'}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text("📍 ${data['userAddress'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),

                    const Divider(color: Colors.white10, height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // বর্তমান স্ট্যাটাস
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Icon(displayStatus == 'Pending' ? Icons.pending : displayStatus == 'Accepted' ? Icons.check_circle : Icons.done_all, color: statusColor, size: 14),
                              const SizedBox(width: 5),
                              Text(displayStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),

                        // যদি ইউজার ইতোমধ্যে পে করে ফেলে, টেকনিশিয়ানের আর কোনো বাটন দরকার নেই
                        if (currentStatus == 'Paid')
                          const Text("User Paid", style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold))
                        else
                          DropdownButton<String>(
                            value: currentStatus,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            underline: Container(),
                            icon: const Icon(Icons.edit_note, color: Color(0xFFFFC65C), size: 20),
                            items: const [
                              DropdownMenuItem(value: "Pending", child: Text("Pending", style: TextStyle(color: Colors.orange))),
                              DropdownMenuItem(value: "Accepted", child: Text("Accept", style: TextStyle(color: Colors.blue))),
                              DropdownMenuItem(value: "Completed", child: Text("Complete", style: TextStyle(color: Colors.green))),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null && newValue != currentStatus) {
                                doc.reference.update({'status': newValue});
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}