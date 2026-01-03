import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'dart:math';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotifications = true;
  bool hapticFeedback = true;
  bool darkMode = true;
  bool _isLoading = false;

  // --- JOIN HOUSEHOLD ---
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
          decoration: const InputDecoration(
            hintText: "Enter 6-digit code",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final query = await FirebaseFirestore.instance
                  .collection('households')
                  .where('inviteCode', isEqualTo: code)
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                final householdId = query.docs.first.id;
                final userId = authService.value.currentUser?.uid;

                // Update: Add to the array of householdIds
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'householdIds': FieldValue.arrayUnion([householdId]),
                  'currentHouseholdId': householdId, 
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Joined successfully!")));
                }
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  // --- GENERATE NEW HOUSEHOLD ---
  Future<void> _generateNewHousehold() async {
    final user = authService.value.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      String newInviteCode = (Random().nextInt(900000) + 100000).toString();
      DocumentReference householdRef = await FirebaseFirestore.instance.collection('households').add({
        'inviteCode': newInviteCode,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'name': "Home ${newInviteCode.substring(0,3)}",
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'householdIds': FieldValue.arrayUnion([householdRef.id]),
        'currentHouseholdId': householdRef.id,
      }, SetOptions(merge: true)); // Use merge to ensure the document is created/updated safely

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Created! Code: $newInviteCode")));
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LEAVE HOUSEHOLD ---
  Future<void> _leaveHousehold(String householdId) async {
    final userId = authService.value.currentUser?.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'householdIds': FieldValue.arrayRemove([householdId]),
    });
    
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = userDoc.data() as Map<String, dynamic>?;
    List ids = (data != null && data.containsKey('householdIds')) ? data['householdIds'] : [];
    
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'currentHouseholdId': ids.isNotEmpty ? ids.first : "",
    });
  }

  // --- SWITCH ACTIVE LIST ---
  void _switchList(String householdId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(authService.value.currentUser?.uid)
        .update({'currentHouseholdId': householdId});
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(user),
            const SizedBox(height: 30),

            _sectionHeader("YOUR HOUSEHOLDS"),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const LinearProgressIndicator();
                }
                
                // FIXED: Safe check for householdIds field
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                List householdIds = (userData != null && userData.containsKey('householdIds')) 
                    ? userData['householdIds'] 
                    : [];
                String currentId = (userData != null && userData.containsKey('currentHouseholdId')) 
                    ? userData['currentHouseholdId'] 
                    : "";

                return Column(
                  children: [
                    _buildSettingsGroup([
                      ...householdIds.map((id) => _buildHouseholdTile(id, currentId)),
                      GestureDetector(
                        onTap: _isLoading ? null : _generateNewHousehold,
                        child: _buildListTile(Icons.add_home_rounded, "Create New List", iconBgColor: Colors.green.withOpacity(0.2)),
                      ),
                      GestureDetector(
                        onTap: _showJoinHouseholdDialog,
                        child: _buildListTile(Icons.group_add_rounded, "Join Another Household", iconBgColor: Colors.blue.withOpacity(0.2)),
                      ),
                    ]),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
            _sectionHeader("PREFERENCES"),
            _buildSettingsGroup([
              _buildSwitchTile(Icons.notifications_rounded, "Push Notifications", pushNotifications, (val) => setState(() => pushNotifications = val), iconBgColor: Colors.red.withOpacity(0.15)),
              _buildSwitchTile(Icons.dark_mode_rounded, "Dark Mode", darkMode, (val) => setState(() => darkMode = val), iconBgColor: Colors.indigo.withOpacity(0.15)),
            ]),

            const SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdTile(String householdId, String activeId) {
    bool isActive = householdId == activeId;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('households').doc(householdId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        String name = data?['name'] ?? "Loading...";
        String code = data?['inviteCode'] ?? "------";

        return ListTile(
          onTap: () => _switchList(householdId),
          leading: Icon(isActive ? Icons.radio_button_checked : Icons.radio_button_off, color: isActive ? Colors.blue : Colors.grey),
          title: Text(name, style: TextStyle(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text("Code: $code", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 20),
            onPressed: () => _leaveHousehold(householdId),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(user) {
    return Row(
      children: [
        CircleAvatar(radius: 35, backgroundColor: Colors.blue.withOpacity(0.1), child: Text(user?.displayName?.substring(0,1).toUpperCase() ?? "U", style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold))),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.displayName ?? "User", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(user?.email ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: OutlinedButton(
        onPressed: () async { await authService.value.signOut(); Navigator.pop(context); },
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(decoration: BoxDecoration(color: const Color(0xFF1A242E), borderRadius: BorderRadius.circular(20)), child: Column(children: children));
  }

  Widget _buildListTile(IconData icon, String title, {required Color iconBgColor}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
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