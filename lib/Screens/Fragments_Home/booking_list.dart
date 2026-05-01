import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Booking_Success.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Text("Please login", style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Bookings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFFFC65C)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('bookingTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC65C)),
            );

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 70,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No Active Bookings!",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          var activeDocs = snapshot.data!.docs.where((doc) {
            String status = doc['status'];
            return status == 'Pending' ||
                status == 'Accepted' ||
                status == 'Completed';
          }).toList();

          if (activeDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 70,
                    color: Colors.green,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "All Clear!",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              var doc = activeDocs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'Pending';

              Color statusColor = status == 'Accepted'
                  ? Colors.blueAccent
                  : status == 'Completed'
                  ? Colors.greenAccent
                  : const Color(0xFFFFC65C);
              IconData statusIcon = status == 'Accepted'
                  ? Icons.thumb_up_alt_outlined
                  : status == 'Completed'
                  ? Icons.done_all
                  : Icons.hourglass_empty_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    collapsedIconColor: Colors.white54,
                    iconColor: statusColor,
                    title: Text(
                      data['techName'] ?? "Technician",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            const Divider(color: Colors.white10),
                            _buildDetailRow(
                              Icons.settings_suggest_outlined,
                              "Service",
                              data['techCategory'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              Icons.event_available,
                              "Date",
                              data['date'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              Icons.alarm,
                              "Time",
                              data['time'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              "Address",
                              data['userAddress'] ?? 'N/A',
                            ),
                            if (data['problem'] != null &&
                                data['problem'].toString().isNotEmpty)
                              _buildDetailRow(
                                Icons.description_outlined,
                                "Problem",
                                data['problem'],
                              ),
                            const SizedBox(height: 15),
                            if (status == 'Completed')
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingSuccessScreen(
                                          bookingId: doc.id,
                                          technicianId: data['techDocId'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.payment, size: 20),
                                  label: const Text(
                                    "Complete & Pay",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFFC65C)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ StatefulWidget করা হয়েছে এবং আগের আন্ডারস্কোর (_) রিমুভ করা হয়েছে
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  // ✅ এটিই মূল ট্রিক: প্রথমবার লোড হচ্ছে কি না তা ট্র্যাক করবে
  bool _isFirstLoad = true;

  String _formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      String month = _getMonthName(dt.month);
      int hour = dt.hour;
      String minute = dt.minute.toString().padLeft(2, '0');
      String amPm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return "${dt.day} $month ${dt.year}, $hour:$minute $amPm";
    } catch (e) {
      return "N/A";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Booking History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'Paid')
            // ✅ .orderBy বাদ দেওয়া হয়েছে যাতে ইনডেক্স এরর না আসে
            .snapshots(),
        builder: (context, snapshot) {
          if (_isFirstLoad &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC65C)),
            );
          }

          if (snapshot.hasData) {
            _isFirstLoad = false;
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No past bookings yet.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          // ✅ লোকালি সর্টিং (ফায়ারবেস এর বদলে অ্যাপের ভেতরে নতুনের উপরে রাখা হচ্ছে)
          var allDocs = snapshot.data!.docs;
          allDocs.sort((a, b) {
            String timeA = a['bookingTime'] ?? '';
            String timeB = b['bookingTime'] ?? '';
            return timeB.compareTo(timeA); // Descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allDocs.length,
            itemBuilder: (context, index) {
              var data = allDocs[index].data() as Map<String, dynamic>;
              String rawTime = data['bookingTime'] ?? '';
              String formattedDateTime = _formatDate(rawTime);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['techName'] ?? "Technician",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${data['techCategory'] ?? 'Service'} • Paid via ${data['paymentMethod'] ?? 'N/A'}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Colors.white38,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Completed on: $formattedDateTime",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
