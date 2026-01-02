import 'package:flutter/material.dart';
import 'auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock states for switches
  bool pushNotifications = true;
  bool hapticFeedback = true;
  bool darkMode = true;

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // --- PROFILE HEADER ---
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/profile_placeholder.png'), // Replace with user image if available
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0F1720), width: 2),
                        ),
                        child: const Text("PRO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? "User Name",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      user?.email ?? "email@example.com",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: const [
                        Text("Edit Profile", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                        SizedBox(width: 5),
                        Icon(Icons.edit, color: Colors.blue, size: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- HOUSEHOLD & COLLAB ---
            _sectionHeader("HOUSEHOLD & COLLAB"),
            _buildSettingsGroup([
              _buildListTile(Icons.people_alt_rounded, "Manage Household", showArrow: true, iconBgColor: Colors.blue.withOpacity(0.2)),
              _buildListTile(Icons.person_add_alt_1_rounded, "Invite Partner", trailingText: "Free", showArrow: true, iconBgColor: Colors.blue.withOpacity(0.2)),
            ]),

            const SizedBox(height: 25),

            // --- PREFERENCES ---
            _sectionHeader("PREFERENCES"),
            _buildSettingsGroup([
              _buildSwitchTile(Icons.notifications_rounded, "Push Notifications", pushNotifications, (val) => setState(() => pushNotifications = val), iconBgColor: Colors.red.withOpacity(0.15)),
              _buildSwitchTile(Icons.vibration_rounded, "Haptic Feedback", hapticFeedback, (val) => setState(() => hapticFeedback = val), iconBgColor: Colors.orange.withOpacity(0.15)),
              _buildSwitchTile(Icons.dark_mode_rounded, "Dark Mode", darkMode, (val) => setState(() => darkMode = val), iconBgColor: Colors.indigo.withOpacity(0.15)),
            ]),

            const SizedBox(height: 25),

            // --- DATA & SYNC ---
            _sectionHeader("DATA & SYNC"),
            _buildSettingsGroup([
              _buildListTile(Icons.sync_rounded, "Sync Status", trailingText: "Up to date", isSyncStatus: true, iconBgColor: Colors.teal.withOpacity(0.15)),
              _buildListTile(Icons.cleaning_services_rounded, "Clear Cache", subtitle: "Free up local space", showArrow: true, iconBgColor: Colors.grey.withOpacity(0.15)),
            ]),

            const SizedBox(height: 40),

            // --- LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () async {
                  await authService.value.signOut();
                  if (mounted) Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E1E1E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.5),
                ),
                child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "GroceryShare v2.4.1 (Build 204)",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A242E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, String? trailingText, bool showArrow = false, bool isSyncStatus = false, required Color iconBgColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncStatus) ...[
            const Icon(Icons.circle, color: Colors.cyanAccent, size: 8),
            const SizedBox(width: 8),
          ],
          if (trailingText != null) 
            Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          if (showArrow) 
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged, {required Color iconBgColor}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
        activeTrackColor: Colors.blue.withOpacity(0.3),
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }
}