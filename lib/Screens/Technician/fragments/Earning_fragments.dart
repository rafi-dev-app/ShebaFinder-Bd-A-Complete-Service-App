// ==========================================
// ৩. আয় (Earnings)
// ==========================================

import 'package:flutter/material.dart';
class TechEarnings extends StatelessWidget {
  const TechEarnings();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Earnings", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFC65C).withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text("Total Balance", style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 10),
                  Text("৳ 12,500", style: TextStyle(color: Color(0xFFFFC65C), fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildEarningCard("This Week", "৳ 3,200", Icons.trending_up)),
                const SizedBox(width: 15),
                Expanded(child: _buildEarningCard("Pending", "৳ 1,500", Icons.hourglass_top)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEarningCard(String title, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFC65C)),
          const SizedBox(height: 10),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
