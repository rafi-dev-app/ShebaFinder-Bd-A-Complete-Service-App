import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shebafinderbdnew/Screens/RoleSelection.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // User Data Variables
  String _userName = "User";
  String _userEmail = "";
  String _userImageBase64 = "";
  Uint8List? _profileImageBytes;

  // Address Variables
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingAddresses = true;

  // Notification Toggle
  bool _isNotificationOn = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAddresses();
  }

  // Fetching Main Profile Data
  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? "";
        _userName = user.displayName ?? "User";
      });

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? _userName;
          _userImageBase64 = data['imageBase64'] ?? "";
          if (_userImageBase64.isNotEmpty) {
            try {
              _profileImageBytes = base64Decode(_userImageBase64);
            } catch (e) {
              _profileImageBytes = null;
            }
          }
        });
      }
    }
  }

  // Fetching Saved Addresses from Sub-collection
  void _fetchAddresses() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _savedAddresses = snapshot.docs
                  .map(
                    (doc) => {
                      'id': doc.id,
                      'address': doc['address'],
                      'label': doc['label'],
                    },
                  )
                  .toList();
              _isLoadingAddresses = false;
            });
          });
    }
  }

  // ================= STEP 1: IMAGE PICKING =================
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Camera/Gallery Dialog ta close korbe

    final ImagePicker picker = ImagePicker();
    // ✅ imageQuality ও maxWidth দিয়ে ছবি অটোমেটিক কম্প্রেস হচ্ছে
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50, // 0-100 এর মধ্যে। 50 মানে মিডিয়াম কোয়ালিটি (সাইজ অনেক কমে যাবে)
      maxWidth: 512,    // ছবির সর্বোচ্চ প্রস্থ সেট করা হয়েছে
      maxHeight: 512,   // ছবির সর্বোচ্চ উচ্চতা সেট করা হয়েছে
    );

    if (image != null) {
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // Image pick korar por sei image niye Edit Dialog e pathabe
      _showEditDialog(selectedImageBase64: base64String);
    }
  }

  // ================= STEP 2: EDIT PROFILE DIALOG =================
  // ================= STEP 2: EDIT PROFILE DIALOG =================
  void _showEditDialog({String? selectedImageBase64}) {
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    String dialogImageBase64 = selectedImageBase64 ?? _userImageBase64;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      // ✅ এখানেও একই কম্প্রেশন যোগ করা হলো
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                        maxWidth: 512,
                        maxHeight: 512,
                      );

                      if (image != null) {
                        File file = File(image.path);
                        List<int> bytes = await file.readAsBytes();

                        // ✅ ডায়ালগের ভেতরে ছবি পিক করার সময়ও সাইজ চেক করা হচ্ছে
                        if (bytes.length > 900000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Image is too large! Select a smaller image.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          dialogImageBase64 = base64Encode(bytes);
                        });
                      }
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[800],
                          child: dialogImageBase64.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(dialogImageBase64),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white54,
                                  size: 30,
                                ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap to change photo",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFC65C)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    // ✅ সেভ করার আগে আবারও স্ট্রিং লেংথ চেক করা হচ্ছে
                    if (dialogImageBase64.length > 900000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Image is too large! Cannot save."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    User? user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                            'name': nameController.text.trim(),
                            'imageBase64': dialogImageBase64,
                          }, SetOptions(merge: true));

                      // Firebase Auth এ ও নাম আপডেট করে দিচ্ছি
                      await user.updateDisplayName(nameController.text.trim());

                      setState(() {
                        _userName = nameController.text.trim();
                        _userImageBase64 = dialogImageBase64;
                        if (_userImageBase64.isNotEmpty) {
                          _profileImageBytes = base64Decode(_userImageBase64);
                        } else {
                          _profileImageBytes = null;
                        }
                      });

                      if (mounted) Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile Updated!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Failed: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC65C),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= ADD NEW ADDRESS =================
  void _showAddAddressDialog() {
    TextEditingController addressController = TextEditingController();
    TextEditingController labelController = TextEditingController(text: "Home");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Add New Address",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Label (e.g. Home, Office)",
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC65C)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: addressController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Full Address",
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC65C)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (addressController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('addresses')
                    .add({
                      'label': labelController.text.trim(),
                      'address': addressController.text.trim(),
                      'createdAt': DateTime.now(),
                    });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Address Saved!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC65C),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= TOP PROFILE SECTION =================
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Image Container
                    GestureDetector(
                      onTap: () {
                        // Step 1: Camera or Gallery choice dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              "Change Photo",
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFFFFC65C),
                                  ),
                                  title: const Text(
                                    "Camera",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickImage(ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.photo_library,
                                    color: Color(0xFFFFC65C),
                                  ),
                                  title: const Text(
                                    "Gallery",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () => _pickImage(ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFC65C),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          child: _profileImageBytes != null
                              ? ClipOval(
                                  child: Image.memory(
                                    _profileImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white54,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _userEmail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        // Shudhu name edit korar jonno
                        onPressed: () => _showEditDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC65C),
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ================= SAVED ADDRESSES SECTION =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Saved Addresses",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddAddressDialog,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFFFFC65C),
                              size: 20,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Add New",
                              style: TextStyle(
                                color: Color(0xFFFFC65C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoadingAddresses
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFC65C),
                          ),
                        )
                      : _savedAddresses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: Text(
                            "No addresses saved yet.",
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _savedAddresses.length,
                          itemBuilder: (context, index) {
                            var addr = _savedAddresses[index];
                            return Dismissible(
                              key: Key(addr['id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                              onDismissed: (direction) async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .collection('addresses')
                                    .doc(addr['id'])
                                    .delete();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFFFC65C),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            addr['label'] ?? "Address",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            addr['address'],
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white10,
              height: 40,
              indent: 20,
              endIndent: 20,
            ),

            // ================= OTHER SETTINGS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFFFFC65C),
                      ),
                    ),
                    title: const Text(
                      "Notifications",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    subtitle: const Text(
                      "Booking updates & offers",
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    value: _isNotificationOn,
                    activeColor: const Color(0xFFFFC65C),
                    onChanged: (val) => setState(() => _isNotificationOn = val),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.info_outline, "About Us", onTap: () {}),
                  _buildMenuItem(
                    Icons.privacy_tip_outlined,
                    "Privacy Policy",
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    Icons.help_outline,
                    "Help & Support",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white10,
              height: 40,
              indent: 20,
              endIndent: 20,
            ),

            // ================= LOGOUT SECTION =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                onTap: () async {
                  bool? confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(color: Colors.white54),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Yes, Logout",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmLogout == true) {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: Colors.redAccent),
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white24,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFFFC65C)),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 16,
      ),
    );
  }
}
