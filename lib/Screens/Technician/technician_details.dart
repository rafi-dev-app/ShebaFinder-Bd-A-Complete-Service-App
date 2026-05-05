import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Booking_Success.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../HomePage.dart';

class TechnicianDetailScreen extends StatefulWidget {
  final String docId;

  const TechnicianDetailScreen({super.key, required this.docId});

  @override
  State<TechnicianDetailScreen> createState() => _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState extends State<TechnicianDetailScreen> {
  String selectedPriority = "Standard";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  // ✅ বুকিং স্ট্যাটাস ট্র্যাক করার ভ্যারিয়েবল
  String _currentBookingStatus = "none";

  @override
  void initState() {
    super.initState();
    _checkExistingBooking();
  }

  // ✅ আগে থেকে একটিভ বুকিং আছে কিনা চেক করা (Completed বাদ দেওয়া হয়েছে)
  void _checkExistingBooking() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('techDocId', isEqualTo: widget.docId)
        .where('status', whereIn: ['Pending', 'Accepted', 'Completed'])
        .get();

    if (snapshot.docs.isNotEmpty) {
      var latestBooking = snapshot.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _currentBookingStatus = latestBooking['status'] ?? "Pending";
      });
      _listenToBookingStatus();
    }
  }

  // ✅ রিয়েল-টাইমে স্ট্যাটাস আপডেট পাওয়া
  void _listenToBookingStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('techDocId', isEqualTo: widget.docId)
        .where('status', whereIn: ['Pending', 'Accepted', 'Paid'])
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _currentBookingStatus = snapshot.docs.first['status'];
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF101D42),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
      setState(() => _dateController.text = formattedDate);
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF101D42),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() => _timeController.text = pickedTime.format(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Technician Profile",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC65C)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Technician not found",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          var techData = snapshot.data!.data() as Map<String, dynamic>;
          String name = techData['name'] ?? "Technician Name";
          String category = techData['category'] ?? "General";
          String address = techData['address'] ?? "Dhaka, Bangladesh";
          String experience = techData['experience'] ?? "0 Years";
          bool isVerified = techData['status'] == 'approved';

          double totalRatingSum = (techData['totalRatingSum'] ?? 0.0).toDouble();
          int ratingCount = (techData['ratingCount'] ?? 0).toInt();
          double averageRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;

          Uint8List? imageBytes;
          if (techData['imageBase64'] != null && techData['imageBase64'].toString().isNotEmpty) {
            imageBytes = base64Decode(techData['imageBase64']);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ================= PROFILE CARD =================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: imageBytes != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.memory(imageBytes, fit: BoxFit.cover),
                            )
                                : const Icon(Icons.person, size: 50, color: Colors.white54),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
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
                                const SizedBox(height: 8),
                                Text(category, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange, size: 18),
                                    const SizedBox(width: 5),
                                    Text("${averageRating.toStringAsFixed(1)} ($ratingCount Reviews)", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Color(0xFFFFC65C)),
                                    const SizedBox(width: 5),
                                    Flexible(child: Text(address, style: const TextStyle(color: Colors.white60, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Experience", style: TextStyle(color: Color(0xFFFFC65C), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$experience years', style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= DYNAMIC BOTTOM SECTION =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  // ✅ ১. এখানে averageRating পাস করা হয়েছে
                  child: _buildDynamicSection(techData, averageRating),
                ),

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ ২. এখানে currentRating প্যারামিটার রিসিভ করা হয়েছে
  Widget _buildDynamicSection(Map<String, dynamic> techData, double currentRating) {
    // ১. যদি কোনো বুকিংই না থাকে
    if (_currentBookingStatus == "none") {
      return _buildBookingForm(techData);
    }

    // ২. যদি Pending থাকে
    if (_currentBookingStatus == "Pending") {
      return _buildStatusCard("Waiting for technician to accept your request...", Icons.hourglass_top_rounded, Colors.orange);
    }

    // ৩. যদি Accepted থাকে
    if (_currentBookingStatus == "Accepted") {
      return _buildStatusCard("Technician has accepted! Please wait, your booking is being processed.", Icons.check_circle_outline, Colors.blueAccent);
    }

    // ৪. যদি Paid থাকে (রেটিং দেখাবে)
    if (_currentBookingStatus == "Paid") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard("Payment Completed! Service will start soon.", Icons.payment_rounded, Colors.tealAccent),
          const SizedBox(height: 20),
          const Text("Rate this Technician", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // ✅ ৩. এখানে দুটো আর্গুমেন্টই দেওয়া হয়েছে
          TechnicianRatingWidget(
            technicianId: widget.docId,
            currentRating: currentRating,
          ),
        ],
      );
    }

    // ব্যাকআপ
    return _buildStatusCard("This booking was cancelled or rejected.", Icons.block, Colors.redAccent);
  }

  // স্ট্যাটাস কার্ড উইজেট
  Widget _buildStatusCard(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ✅ বুকিং ফর্ম (techData প্যারামিটার হিসেবে নেওয়া হয়েছে)
  Widget _buildBookingForm(Map<String, dynamic> techData) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_calendar, color: Color(0xFF101D42), size: 28),
              SizedBox(width: 15),
              Text("Booking Form", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF101D42))),
            ],
          ),
          const SizedBox(height: 25),
          _buildFormField("Your Name", Icons.person_outline, "Enter your full name", _nameController),
          const SizedBox(height: 15),
          _buildFormField("Phone Number", Icons.phone_outlined, "01XXXXXXXXX", _phoneController),
          const SizedBox(height: 15),
          _buildFormField("Exact Address", Icons.location_on_outlined, "House, Road, Area...", _addressController),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildSmartDateField()),
              const SizedBox(width: 15),
              Expanded(child: _buildSmartTimeField()),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Service Priority", style: TextStyle(color: Color(0xFF101D42), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF101D42)),
                    items: const [
                      DropdownMenuItem(value: "Standard", child: Text("Standard", style: TextStyle(color: Colors.blueGrey))),
                      DropdownMenuItem(value: "Urgent", child: Text("Urgent", style: TextStyle(color: Colors.blueGrey))),
                      DropdownMenuItem(value: "Emergency", child: Text("Emergency", style: TextStyle(color: Colors.blueGrey))),
                    ],
                    onChanged: (String? newValue) {
                      setState(() => selectedPriority = newValue!);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _problemController,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Explain your problem briefly...",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill up Name and Phone Number"), backgroundColor: Colors.red));
                  return;
                }
                if (_dateController.text.trim().isEmpty || _timeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Date and Time"), backgroundColor: Colors.red));
                  return;
                }

                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!"), backgroundColor: Colors.red));
                  return;
                }
                try {
                  // ... ভ্যালিডেশন চেকগুলো (যেগুলো আগে আছে) ...

                  double totalSum = (techData['totalRatingSum'] ?? 0.0).toDouble();
                  int count = (techData['ratingCount'] ?? 0).toInt();
                  double avgRating = count > 0 ? (totalSum / count) : 0.0;

                  DocumentReference docRef = await FirebaseFirestore.instance
                      .collection('bookings')
                      .add({
                    'userId': currentUser.uid,
                    'userName': _nameController.text.trim(),
                    'userPhone': _phoneController.text.trim(),
                    'userAddress': _addressController.text.trim(),
                    'date': _dateController.text.trim(),
                    'time': _timeController.text.trim(),
                    'problem': _problemController.text.trim(),
                    'priority': selectedPriority,
                    'techName': techData['name'] ?? '',
                    'techCategory': techData['category'] ?? '',
                    'techRating': avgRating,
                    'techImageBase64': techData['imageBase64'] ?? '',
                    'techDocId': widget.docId,
                    'bookingTime': DateTime.now().toIso8601String(),
                    'status': 'Pending',
                  });

                  if (mounted) {
                    // ✅ নতুন লজিক: প্রথমে একটি ধন্যবাদক দেখাবে
                    showDialog(
                      context: context,
                      barrierDismissible: false, // বাইরে ট্যাপ করে ডায়ালগ বন্ধ করা যাবে না
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white, // বুকিং ফর্মের সাথে ম্যাচ করার জন্য সাদা রাখা হলো
                          title: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 60,
                          ),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Thank you so much for booking!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "The technician will review your request shortly. You can pay and track your booking from the 'My Bookings' tab.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                // ডায়ালগ বন্ধ করে দিচ্ছে
                                Navigator.pop(context);

                                // তারপর পেমেন্ট/বুকিং স্ক্রিনে নিয়ে যাবে
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(initialIndex: 1),
                                  ),
                                );
                              },
                              child: const Text(
                                "See Booking",
                                style: TextStyle(
                                  color: Color(0xFF101D42),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Booking Failed: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC65C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("Confirm Booking & Proceed", style: TextStyle(color: Color(0xFF101D42), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // অন্যান্য হেল্পার উইজেট
  Widget _buildFormField(String label, IconData icon, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF101D42), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF101D42), size: 20),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Date", style: TextStyle(color: Color(0xFF101D42), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: _dateController,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Select Date",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF101D42), size: 20),
                suffixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF101D42), size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Time", style: TextStyle(color: Color(0xFF101D42), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _selectTime,
          child: AbsorbPointer(
            child: TextField(
              controller: _timeController,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: "09:00 AM",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.access_time_outlined, color: Color(0xFF101D42), size: 20),
                suffixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF101D42), size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}