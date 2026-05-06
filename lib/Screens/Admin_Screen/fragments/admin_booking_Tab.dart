// ==========================================
// ৪. অ্যাডমিন বুকিং কন্ট্রোল পেজ
// ==========================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class AdminBookingsTab extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('bookingTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No bookings found", style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String currentStatus = data['status'] ?? "Pending";

            // স্ট্যাটাস অনুযায়ী কালার
            Color statusColor = currentStatus == 'Pending' ? Colors.orange :
            currentStatus == 'Accepted' ? Colors.blue :
            Colors.green; // Completed

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User: ${data['userName'] ?? "Unknown"}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Technician: ${data['techName'] ?? "N/A"} (${data['techCategory']})",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // বর্তমান স্ট্যাটাস দেখাচ্ছে
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentStatus,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),

                      // স্ট্যাটাস চেঞ্জ করার ড্রপডাউন
                      DropdownButton<String>(
                        value: currentStatus,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        underline: Container(),
                        icon: const Icon(Icons.edit, color: Color(0xFFFFC65C), size: 18),
                        items: const [
                          DropdownMenuItem(value: "Pending", child: Text("Pending", style: TextStyle(color: Colors.orange))),
                          DropdownMenuItem(value: "Accepted", child: Text("Accepted", style: TextStyle(color: Colors.blue))),
                          DropdownMenuItem(value: "Completed", child: Text("Completed", style: TextStyle(color: Colors.green))),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            // ফায়ারবেসে স্ট্যাটাস আপডেট করা হচ্ছে
                            doc.reference.update({'status': newValue});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Status updated to $newValue"),
                                backgroundColor: newValue == 'Completed' ? Colors.green : Colors.blue,
                              ),
                            );
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
    );
  }
}