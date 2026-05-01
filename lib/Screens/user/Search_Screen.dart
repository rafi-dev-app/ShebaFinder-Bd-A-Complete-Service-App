import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shebafinderbdnew/Screens/Technician/technician_details.dart';
import 'package:shebafinderbdnew/widgets/BlinkDot.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "e.g. Uttara Electrician",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFC65C)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildEmptyState()
          : _buildSearchResults(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.white24),
          SizedBox(height: 15),
          Text(
            "Try searching like:\n'Uttara Electrician' or\n'Mirpur Cleaner'",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technicians')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC65C)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No technicians available", style: TextStyle(color: Colors.white54)));
        }

        // Search query ke alada kora holo (Example: "uttara electrician" -> ["uttara", "electrician"])
        List<String> searchWords = _searchQuery.split(' ').where((word) => word.isNotEmpty).toList();

        // Local Filtering Logic
        final filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String category = (data['category'] ?? '').toString().toLowerCase();
          String address = (data['address'] ?? '').toString().toLowerCase();

          // CASE 1: Jekuno ekta word diye search korle (Only "Electrician" ba only "Uttara")
          if (searchWords.length == 1) {
            String query = searchWords[0];
            return category.contains(query) || address.contains(query);
          }

          // CASE 2: Dui ba tar beshi word diye search korle (Example: "Uttara Electrician")
          bool hasMatchInAddress = false;
          bool hasMatchInCategory = false;

          for (String word in searchWords) {
            if (address.contains(word)) {
              hasMatchInAddress = true;
            }
            if (category.contains(word)) {
              hasMatchInCategory = true;
            }
          }

          // Duitai mile gele true return korbe.
          // (Example: Address e "uttara" ase AND Category te "electrician" ase)
          return hasMatchInAddress && hasMatchInCategory;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 60, color: Colors.white24),
                const SizedBox(height: 15),
                Text(
                  "No results found for '$_searchQuery'",
                  style: const TextStyle(color: Colors.white54, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];
            var data = doc.data() as Map<String, dynamic>;

            String name = data['name'] ?? "Unknown";
            String category = data['category'] ?? "General";
            String address = data['address'] ?? "Dhaka";
            String experience = data['experience'] ?? "0 Years";

            double totalRatingSum = (data['totalRatingSum'] ?? 0.0).toDouble();
            int ratingCount = (data['ratingCount'] ?? 0).toInt();
            double averageRating = ratingCount > 0 ? (totalRatingSum / ratingCount) : 0.0;
            bool isAvailable = data['isAvailable'] ?? false;

            Uint8List? imageBytes;
            if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty) {
              try {
                imageBytes = base64Decode(data['imageBase64']);
              } catch (e) {
                imageBytes = null;
              }
            }

            return _buildSearchCard(
              context: context,
              docId: doc.id,
              name: name,
              category: category,
              address: address,
              experience: experience,
              rating: averageRating.toStringAsFixed(1),
              isAvailable: isAvailable,
              imageBytes: imageBytes,
              searchQuery: _searchQuery,
            );
          },
        );
      },
    );
  }

  // Search Result Card UI
  Widget _buildSearchCard({
    required BuildContext context,
    required String docId,
    required String name,
    required String category,
    required String address,
    required String experience,
    required String rating,
    required bool isAvailable,
    required Uint8List? imageBytes,
    required String searchQuery,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianDetailScreen(docId: docId)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(15),
              ),
              child: imageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(imageBytes, fit: BoxFit.cover))
                  : const Icon(Icons.person, color: Colors.white54, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: _getHighlightedText(category, searchQuery),
                          style: TextStyle(
                            color: _isMatched(category, searchQuery) ? const Color(0xFFFFC65C) : Colors.white54,
                            fontWeight: _isMatched(category, searchQuery) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const TextSpan(text: " • ", style: TextStyle(color: Colors.white38)),
                        TextSpan(
                          text: _getHighlightedText(address, searchQuery),
                          style: TextStyle(
                            color: _isMatched(address, searchQuery) ? const Color(0xFFFFC65C) : Colors.white38,
                            fontWeight: _isMatched(address, searchQuery) ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.work_history_outlined, color: Colors.blue, size: 12),
                      const SizedBox(width: 3),
                      Text(experience, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 3),
                      Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      const Spacer(),
                      if (isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              BlinkingDot(color: Colors.greenAccent, size: 6),
                              SizedBox(width: 4),
                              Text("Available", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        const Text("Busy", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  // Check korbe kono word match korche kina
  bool _isMatched(String originalText, String fullQuery) {
    List<String> searchWords = fullQuery.split(' ').where((word) => word.isNotEmpty).toList();
    for (String word in searchWords) {
      if (originalText.toLowerCase().contains(word)) {
        return true;
      }
    }
    return false;
  }

  // Original text return korbe (Color change UI te handle kora hoyeche)
  String _getHighlightedText(String originalText, String query) {
    return originalText;
  }
}