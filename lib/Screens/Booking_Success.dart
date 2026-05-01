import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/HomePage.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_rating.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String bookingId;
  final String technicianId;

  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    required this.technicianId,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  String _selectedPayment = "Cash on Delivery";
  bool _isPaymentDone = false;
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    "Cash on Delivery",
    "bKash",
    "Nagad",
    "Card Payment",
  ];

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // ফায়ারস্টোরে স্ট্যাটাস আপডেট করা হচ্ছে
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'status': 'Paid', 'paymentMethod': _selectedPayment});

      if (mounted) {
        setState(() {
          _isPaymentDone = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ✅ হেডার আইকন
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isPaymentDone
                          ? Colors.green.withOpacity(0.3)
                          : const Color(0xFFFFC65C).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _isPaymentDone ? Icons.check_circle : Icons.pending_outlined,
                  size: 100,
                  color: _isPaymentDone
                      ? Colors.green
                      : const Color(0xFFFFC65C),
                ),
              ),

              const SizedBox(height: 30),
              Text(
                _isPaymentDone ? "Payment Successful!" : "Confirm Your Payment",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isPaymentDone
                    ? "Please rate the technician below."
                    : "Select a payment method to proceed.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),

              const SizedBox(height: 40),

              // ✅ পেমেন্ট অপশনগুলো (পে করার আগে দেখাবে)
              if (!_isPaymentDone) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Payment Method",
                    style: TextStyle(
                      color: Color(0xFFFFC65C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                ..._paymentMethods.map((method) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _selectedPayment == method
                          ? const Color(0xFF1E293B)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _selectedPayment == method
                            ? const Color(0xFFFFC65C)
                            : Colors.white24,
                      ),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        method,
                        style: TextStyle(
                          color: _selectedPayment == method
                              ? Colors.white
                              : Colors.white54,
                          fontWeight: _selectedPayment == method
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      value: method,
                      groupValue: _selectedPayment,
                      activeColor: const Color(0xFFFFC65C),
                      onChanged: (value) {
                        setState(() => _selectedPayment = value!);
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 30),

                // ✅ পে করার বাটন
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Confirm Payment",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),
              ],
              // ✅ রেটিং উইজেট (পেমেন্ট হয়ে গেলে দেখাবে)
              if (_isPaymentDone) ...[
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),

                // ফায়ারবেস থেকে টেকনিশিয়ানের বর্তমান রেটিং আনার জন্য FutureBuilder
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('technicians')
                      .doc(widget.technicianId)
                      .get(),
                  builder: (context, snapshot) {
                    // যতক্ষণ ডাটা আসছে ততক্ষণ লোডিং দেখাবে
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFC65C),
                        ),
                      );
                    }

                    double rating = 0.0;

                    // ডাটা পেলে রেটিং ক্যালকুলেশন করবে
                    if (snapshot.hasData && snapshot.data!.exists) {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      double totalSum = (data['totalRatingSum'] ?? 0.0)
                          .toDouble();
                      int count = (data['ratingCount'] ?? 0).toInt();
                      rating = count > 0 ? (totalSum / count) : 0.0;
                    }

                    // এখানে ঠিকমতো দুটো আর্গুমেন্টই পাস করা হচ্ছে
                    return TechnicianRatingWidget(
                      technicianId: widget.technicianId,
                      currentRating: rating,
                    );
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF101D42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
