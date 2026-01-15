import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'item_model.dart';
import 'settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math';

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {

  late CollectionReference _firestore;
  String? _selectedHouseholdId;
  String? _selectedHouseholdName;
  bool _isInitializing = false;

  final TextEditingController _itemController = TextEditingController();
  int _quantity = 1;

  Stream<bool> _getSyncStatus() {
    return Connectivity().onConnectivityChanged.asyncMap((results) async {
      final hasNetwork = results.contains(ConnectivityResult.mobile) || 
                         results.contains(ConnectivityResult.wifi);
      
      if (!hasNetwork) return false;

      try {
        if (_selectedHouseholdId != null) {
          final snapshot = await _firestore.get(const GetOptions(source: Source.serverAndCache));
          return !snapshot.metadata.hasPendingWrites;
        }
      } catch (_) {}
      return true;
    });
  }

  Future<void> _handleRefresh() async {
    try {
      if (_selectedHouseholdId != null) {
        await FirebaseFirestore.instance
            .collection('households')
            .doc(_selectedHouseholdId)
            .collection('items')
            .get(const GetOptions(source: Source.server));
      } else {
        final userId = authService.value.currentUser?.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.server));
      }
    } catch (e) {
      debugPrint("Refresh failed: $e");
    }
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
              decoration: const InputDecoration(
                hintText: "Household Name (e.g. My Home)",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Invite Code:", style: TextStyle(color: Colors.grey)),
                  Text(generatedCode, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(authService.value.currentUser?.uid)
                    .update({
                      'householdIds': FieldValue.arrayUnion([householdId])
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

  Future<void> _enterHousehold(String householdId, String name) async {
    setState(() {
      _isInitializing = true;
      _selectedHouseholdId = householdId;
      _selectedHouseholdName = name;
    });

    _firestore = FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('items');

    if (mounted) setState(() => _isInitializing = false);
  }

  void _addItem() async {
    if (_itemController.text.trim().isNotEmpty) {
      try {
        await _firestore.add({
          'name': _itemController.text.trim(),
          'quantity': _quantity,
          'isDone': false,
          'userId': authService.value.currentUser?.uid,
          'userName': authService.value.currentUser?.displayName ?? authService.value.currentUser?.email ?? "User",
          'createdAt': FieldValue.serverTimestamp(),
        });
        _itemController.clear();
        setState(() => _quantity = 1);
      } catch (e) {
        debugPrint("Add failed: $e");
      }
    }
  }

  void _deleteItem(String docId) {
    _firestore.doc(docId).delete();
  }

  void _showEditDialog(GroceryItem item) {
    final TextEditingController editNameController = TextEditingController(text: item.name);
    int tempQuantity = item.quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A242E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Item", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: editNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true, fillColor: const Color(0xFF0F1720),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.blue, size: 30), onPressed: () => {if (tempQuantity > 1) setModalState(() => tempQuantity--)}),
                      Text("$tempQuantity", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 30), onPressed: () => setModalState(() => tempQuantity++)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        _firestore.doc(item.id).update({'name': editNameController.text.trim(), 'quantity': tempQuantity});
                        Navigator.pop(context);
                      },
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getInitials(Map<String, dynamic>? data) {
    String name = data?['userName'] ?? "User";
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : "U";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.blue,
        backgroundColor: const Color(0xFF1A242E),
        child: _selectedHouseholdId == null 
            ? _buildHouseholdPickerView() 
            : _isInitializing 
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : _buildGroceryListView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: _selectedHouseholdId != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => setState(() {
                _selectedHouseholdId = null;
                _selectedHouseholdName = null;
              }),
            )
          : null,
      title: Column(
        children: [
          Text(_selectedHouseholdName ?? "My Households", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          StreamBuilder<bool>(
            stream: _getSyncStatus(),
            builder: (context, snapshot) {
              bool isSynced = snapshot.data ?? false;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSynced)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                      ),
                    )
                  else
                    const Icon(Icons.circle, size: 8, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    isSynced ? "Synced" : "Offline Mode", 
                    style: TextStyle(
                      fontSize: 10, 
                      color: isSynced ? Colors.grey : Colors.orange,
                      fontWeight: isSynced ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())), 
          icon: const Icon(Icons.settings, color: Colors.white)
        ),
      ],
    );
  }

  Widget _buildHouseholdPickerView() {
    final userId = authService.value.currentUser?.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List ids = (data != null && data.containsKey('householdIds')) ? data['householdIds'] : [];
        
        return Column(
          children: [
            Expanded(
              child: ids.isEmpty 
                ? _buildEmptyStateContent()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: ids.length,
                    itemBuilder: (context, index) => _buildHouseholdCard(ids[index]),
                  ),
            ),

            _buildPersistentActionBar(),
          ],
        );
      },
    );
  }

  Widget _buildPersistentActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A242E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(Icons.add, "Create", _showCreateHouseholdDialog),
          const VerticalDivider(color: Colors.white10, thickness: 1),
          _actionButton(Icons.group_add, "Join", _showJoinHouseholdDialog),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.house_outlined, color: Colors.grey, size: 80),
          const SizedBox(height: 20),
          const Text("No Households Found", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Join or create a household below", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue, size: 20)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(String householdId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('households').doc(householdId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? "Unnamed Household";
        
        return GestureDetector(
          onTap: () => _enterHousehold(householdId, name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1A242E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                const Icon(Icons.home_work_rounded, color: Colors.blue, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Code: ${data?['inviteCode'] ?? '---'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildGroceryListView() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.orderBy('createdAt', descending: true).snapshots(includeMetadataChanges: true),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];
              final items = allDocs.map((doc) => MapEntry(doc.data() as Map<String, dynamic>, GroceryItem.fromMap(doc.id, doc.data() as Map<String, dynamic>, isPending: doc.metadata.hasPendingWrites))).toList();
              final toBuy = items.where((e) => !e.value.isDone).toList();
              final done = items.where((e) => e.value.isDone).toList();
              
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader("TO BUY"),
                  ...toBuy.map((e) => _buildItemCard(e.value, e.key)),
                  const SizedBox(height: 30),
                  _sectionHeader("DONE"),
                  ...done.map((e) => _buildItemCard(e.value, e.key)),
                ],
              );
            },
          ),
        ),
        _buildMinimalistInput(),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2));
  }

  Widget _buildItemCard(GroceryItem item, Map<String, dynamic> rawData) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.redAccent, child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => _deleteItem(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: item.isDone ? Colors.transparent : const Color(0xFF1A242E), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(
            color: item.isPending ? Colors.orange.withOpacity(0.8) : Colors.white10,
            width: item.isPending ? 1.5 : 1,
          )
        ),
        child: ListTile(
          onTap: () => _showEditDialog(item),
          leading: Checkbox(value: item.isDone, activeColor: Colors.blue, onChanged: (val) => _firestore.doc(item.id).update({'isDone': val})),
          title: Row(
            children: [
              Expanded(child: Text(item.name, style: TextStyle(color: Colors.white, decoration: item.isDone ? TextDecoration.lineThrough : null))),
              if (item.isPending)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                ),
            ],
          ),
          subtitle: Text(
            item.isPending ? "Waiting for sync..." : "Qty: ${item.quantity}", 
            style: TextStyle(color: item.isPending ? Colors.orange : Colors.grey, fontSize: 11)
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_note, color: Colors.white24, size: 24), onPressed: () => _showEditDialog(item)),
              const SizedBox(width: 4),
              CircleAvatar(radius: 12, backgroundColor: Colors.blue.withOpacity(0.2), child: Text(_getInitials(rawData), style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(color: Color(0xFF0F1720), border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(child: TextField(controller: _itemController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Add item...", hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF1A242E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A242E), borderRadius: BorderRadius.circular(25)),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.remove, color: Colors.blue, size: 18), onPressed: () => setState(() { if(_quantity > 1) _quantity--; })),
              Text("$_quantity", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, color: Colors.blue, size: 18), onPressed: () => setState(() => _quantity++)),
            ]),
          ),
          const SizedBox(width: 10),
          GestureDetector(onTap: _addItem, child: const CircleAvatar(backgroundColor: Colors.blue, radius: 22, child: Icon(Icons.arrow_upward, color: Colors.white))),
        ],
      ),
    );
  }
}