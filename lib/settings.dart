import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for password/email logic
import 'auth_service.dart';
import 'dart:math';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool hapticFeedback = true;
  bool _isLoading = false;

  // --- 1. COMPREHENSIVE PROFILE EDIT LOGIC ---
  void _showEditProfileDialog(Map<String, dynamic> userData) {
    final user = authService.value.currentUser;
    final TextEditingController nameController = TextEditingController(text: userData['displayName'] ?? "");
    final TextEditingController emailController = TextEditingController(text: userData['email'] ?? "");
    final TextEditingController passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A242E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDialogTextField(nameController, "Display Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildDialogTextField(emailController, "New Email", Icons.email_outlined),
            const SizedBox(height: 15),
            _buildDialogTextField(passwordController, "New Password (Leave blank to keep current)", Icons.lock_outline, isPassword: true),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  try {
                    // Update Username
                    if (nameController.text.trim() != userData['displayName']) {
                      await user?.updateDisplayName(nameController.text.trim());
                    }

                    // Update Email in Firebase Auth
                    if (emailController.text.trim() != user?.email) {
                      await user?.updateEmail(emailController.text.trim());
                    }

                    // Update Password in Firebase Auth
                    if (passwordController.text.isNotEmpty) {
                      await user?.updatePassword(passwordController.text.trim());
                    }

                    // Sync changes to Firestore - This triggers instant UI update in StreamBuilders
                    await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                      'displayName': nameController.text.trim(),
                      'email': emailController.text.trim(),
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile & Security Updated")));
                    }
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Update Failed")));
                  }
                },
                child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0F1720),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  // --- HOUSEHOLD LOGIC ---
  void _showJoinHouseholdDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242E),
        title: const Text("Join Household", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter 6-digit code", hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final query = await FirebaseFirestore.instance
                  .collection('households').where('inviteCode', isEqualTo: code).limit(1).get();

              if (query.docs.isNotEmpty) {
                final householdId = query.docs.first.id;
                await FirebaseFirestore.instance.collection('users').doc(authService.value.currentUser?.uid).update({
                  'householdIds': FieldValue.arrayUnion([householdId]),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  void _showCreateHouseholdDialog() {
    final TextEditingController nameController = TextEditingController();
    String generatedCode = (Random().nextInt(900000) + 100000).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Create Household", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Household Name", hintStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            Text("Invite Code: $generatedCode", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final user = authService.value.currentUser;
              DocumentReference householdRef = await FirebaseFirestore.instance.collection('households').add({
                'inviteCode': generatedCode,
                'createdBy': user?.uid,
                'createdAt': FieldValue.serverTimestamp(),
                'name': nameController.text.trim(),
              });
              await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                'householdIds': FieldValue.arrayUnion([householdRef.id]),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = authService.value.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List householdIds = userData.containsKey('householdIds') ? userData['householdIds'] : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(userData),
                const SizedBox(height: 30),

                _sectionHeader("YOUR HOUSEHOLDS"),
                _buildSettingsGroup([
                  ...householdIds.map((id) => _buildHouseholdTile(id)),
                  GestureDetector(
                    onTap: _showCreateHouseholdDialog,
                    child: _buildListTile(Icons.add_home_rounded, "Create New Household", iconBgColor: Colors.green.withOpacity(0.1)),
                  ),
                  GestureDetector(
                    onTap: _showJoinHouseholdDialog,
                    child: _buildListTile(Icons.group_add_rounded, "Join Household", iconBgColor: Colors.blue.withOpacity(0.1)),
                  ),
                ]),

                const SizedBox(height: 25),
                _sectionHeader("SYSTEM"),
                _buildSettingsGroup([
                  _buildSwitchTile(Icons.vibration_rounded, "Haptic Feedback", hapticFeedback, (val) => setState(() => hapticFeedback = val), iconBgColor: Colors.orange.withOpacity(0.1)),
                  _buildListTile(Icons.info_outline_rounded, "App Version", trailingText: "2.4.1", iconBgColor: Colors.teal.withOpacity(0.1)),
                ]),

                const SizedBox(height: 40),
                _buildLogoutButton(),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    String name = userData['displayName'] ?? "User";
    String email = userData['email'] ?? "";
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Row(
      children: [
        CircleAvatar(
          radius: 35, backgroundColor: Colors.blue.withOpacity(0.1), 
          child: Text(initial, style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold))
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ),
        IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 28), onPressed: () => _showEditProfileDialog(userData)),
      ],
    );
  }

  Widget _buildHouseholdTile(String householdId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('households').doc(householdId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return ListTile(
          leading: const Icon(Icons.house_rounded, color: Colors.blue),
          title: Text(data['name'] ?? "Home", style: const TextStyle(color: Colors.white)),
          subtitle: Text("Invite Code: ${data['inviteCode'] ?? '---'}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 20), onPressed: () {
            FirebaseFirestore.instance.collection('users').doc(authService.value.currentUser?.uid).update({
              'householdIds': FieldValue.arrayRemove([householdId]),
            });
          }),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () async { await authService.value.signOut(); Navigator.pop(context); }, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))));
  }

  Widget _sectionHeader(String title) { return Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))); }

  Widget _buildSettingsGroup(List<Widget> children) { return Container(decoration: BoxDecoration(color: const Color(0xFF1A242E), borderRadius: BorderRadius.circular(20)), child: Column(children: children)); }

  Widget _buildListTile(IconData icon, String title, {String? trailingText, required Color iconBgColor}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: trailingText != null ? Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 12)) : const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged, {required Color iconBgColor}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
    );
  }
}