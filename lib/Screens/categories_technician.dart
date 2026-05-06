import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/widgets/BlinkDot.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_details.dart'; // Import added

class CategoryTechnicianScreen extends StatelessWidget {
  final String categoryName;
  const CategoryTechnicianScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(categoryName, style: const TextStyle(color: Colors.white, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .where('category', isEqualTo: categoryName)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No $categoryName found", style: const TextStyle(color: Colors.white54, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String name = data['name'] ?? "Unknown";
              String experience = data['experience'] ?? "0 Years";

              // Rating Calculation
              double totalRatingSum = (data['totalRatingSum'] ?? 0.0).toDouble();
              int ratingCount = (data['ratingCount'] ?? 0).toInt();
              double averageRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;
              bool isAvailable = data['isAvailable'] ?? false;

              // Image Decoding
              Uint8List? imageBytes;
              if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty) {
                imageBytes = base64Decode(data['imageBase64']);
              }

              return _buildTechnicianCard(
                context: context, // Context pass kora hoyeche
                docId: doc.id,   // docId pass kora hoyeche
                name: name,
                experience: experience,
                rating: averageRating.toStringAsFixed(1),
                isAvailable: isAvailable,
                imageBytes: imageBytes,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard({
    required BuildContext context, // Notun parameter
    required String docId,         // Notun parameter
    required String name,
    required String experience,
    required String rating,
    required bool isAvailable,
    required Uint8List? imageBytes,
  }) {
    return GestureDetector(
      onTap: () {
        // Card e click korle Technician Detail page e jabe abar docId pathabe
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TechnicianDetailScreen(docId: docId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
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
                    : const Icon(Icons.person, color: Colors.white54, size: 40),
              ),
              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Experience
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.work_history_outlined, color: Colors.blue, size: 12),
                              const SizedBox(width: 3),
                              Text(experience, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating + Availability
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 15),

                        if (isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: const [
                                BlinkingDot(color: Colors.greenAccent, size: 8),
                                SizedBox(width: 5),
                                Text("Available Now", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          const Text("Busy", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              // Ekta indicator icon add kora holo jate user bujhe click kora jay
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}