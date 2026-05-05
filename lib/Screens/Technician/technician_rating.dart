import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TechnicianRatingWidget extends StatefulWidget {
  final String technicianId;
  final double currentRating;

  const TechnicianRatingWidget({
    super.key,
    required this.technicianId,
    required this.currentRating,
  });

  @override
  State<TechnicianRatingWidget> createState() => _TechnicianRatingWidgetState();
}

class _TechnicianRatingWidgetState extends State<TechnicianRatingWidget> {
  int _selectedRating = 0;
  bool isSubmitting = false;
  bool hasRated = false; // ✅ নতুন: চেক করার জন্য যে ইউজার ইতিমধ্যে রেটিং দিয়েছে কি না

  Future<void> _submitRating(int rating) async {
    setState(() => isSubmitting = true);

    try {
      DocumentReference techDoc = FirebaseFirestore.instance.collection('technicians').doc(widget.technicianId);

      await techDoc.update({
        'totalRatingSum': FieldValue.increment(rating * 1.0),
        'ratingCount': FieldValue.increment(1),
      });

      if (mounted) {
        setState(() {
          hasRated = true; // ✅ রেটিং সফল হলে hasRated true করে দিচ্ছি
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thanks for your rating!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        // ✅ যদি কোনো কারণে ফেইল করে, তাহলে আবার রেটিং দেওয়ার সুযোগ দেওয়ার জন্য hasRated false সেট করে দিচ্ছি
        setState(() {
          hasRated = false;
          _selectedRating = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Rate this technician", style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 10),

        // Star Selection UI
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            int starNumber = index + 1;
            return IconButton(
              // ✅ লজিক্যাল পরিবর্তন: যদি ইতিমধ্যে রেটিং দিয়ে থাকে (hasRated == true) অথবা সাবমিট হচ্ছে, তাহলে বাটন ডিজেবল করে দেবে
              onPressed: (isSubmitting || hasRated) ? null : () {
                setState(() => _selectedRating = starNumber);
                _submitRating(starNumber);
              },
              icon: Icon(
                starNumber <= _selectedRating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFC65C),
                size: 40,
              ),
            );
          }),
        ),

        const SizedBox(height: 15),

        // ✅ UI পরিবর্তন: রেটিং দেওয়ার আগে যে এভারেজ দেখাচ্ছিল, রেটিং দেওয়ার পর ইউজারের দেওয়া রেটিং দেখাবে
        Text(
          hasRated
              ? "You rated: $_selectedRating/5 ⭐"
              : "Average: ${widget.currentRating.toStringAsFixed(1)} ⭐",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}