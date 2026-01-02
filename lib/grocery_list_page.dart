import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'item_model.dart';
import 'settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('groceries');
  final TextEditingController _itemController = TextEditingController();
  int _quantity = 1;

  // Monitor Sync Status with Connectivity check
  Stream<bool> _getSyncStatus() {
    return Connectivity().onConnectivityChanged.asyncMap((event) async {
      final hasNetwork = event.contains(ConnectivityResult.mobile) || 
                         event.contains(ConnectivityResult.wifi);
      
      if (!hasNetwork) return false;

      // Check if there are local changes waiting to upload
      final snapshot = await _firestore.get(const GetOptions(source: Source.serverAndCache));
      return !snapshot.metadata.hasPendingWrites;
    });
  }

  void _addItem() async {
    if (_itemController.text.trim().isNotEmpty) {
      try {
        await _firestore.add({
          'name': _itemController.text.trim(),
          'quantity': _quantity,
          'isDone': false,
          'userId': authService.value.currentUser?.uid,
          // Save the current display name or email to generate initials later
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

  void _showEditDialog(GroceryItem item, dynamic rawTimestamp) {
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Item", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: editNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F1720),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.blue, size: 30),
                        onPressed: () { if (tempQuantity > 1) setModalState(() => tempQuantity--); },
                      ),
                      Text("$tempQuantity", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 30),
                        onPressed: () => setModalState(() => tempQuantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () {
                        _firestore.doc(item.id).update({
                          'name': editNameController.text.trim(),
                          'quantity': tempQuantity,
                        });
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

  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return "Recently Added";
    if (createdAt is Timestamp) {
      final difference = DateTime.now().difference(createdAt.toDate());
      if (difference.inMinutes < 1) return "Recently Added";
      return timeago.format(createdAt.toDate());
    }
    return "Recently Added";
  }

  // Logic to generate initials (e.g., "John Doe" -> "JD")
  String _getInitials(Map<String, dynamic>? data) {
    String name = data?['userName'] ?? "User";
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : "U";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: StreamBuilder<bool>(
          stream: _getSyncStatus(),
          builder: (context, snapshot) {
            bool isSynced = snapshot.data ?? false;
            return Column(
              children: [
                const Text("Groceries List", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // RECENT CHANGE: Added loading indicator for Offline Mode
                    if (!isSynced)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.circle, size: 8, color: Colors.blue),
                    
                    if (isSynced) const SizedBox(width: 6),
                    
                    Text(
                      isSynced ? "Synced" : "Offline Mode", 
                      style: TextStyle(
                        fontSize: 10, 
                        color: isSynced ? Colors.grey : Colors.orange,
                        fontWeight: isSynced ? FontWeight.normal : FontWeight.bold,
                      )
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())), icon: const Icon(Icons.settings, color: Colors.white)),
        ],
      ),
      body: Column(
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader("TO BUY"),
                    if (toBuy.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text("No items to buy", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ...toBuy.map((e) => _buildItemCard(e.value, e.key['createdAt'], e.key)),
                    
                    const SizedBox(height: 30),
                    _sectionHeader("DONE"),
                    if (done.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text("No completed items", style: TextStyle(color: Colors.grey, fontSize: 12))),
                    ...done.map((e) => _buildItemCard(e.value, e.key['createdAt'], e.key)),
                  ],
                );
              },
            ),
          ),
          _buildMinimalistInput(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2));
  }

  Widget _buildItemCard(GroceryItem item, dynamic rawTime, Map<String, dynamic> rawData) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: item.isDone ? Colors.transparent : const Color(0xFF1A242E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: item.isPending ? Colors.orange.withOpacity(0.5) : Colors.white10),
        ),
        child: ListTile(
          onTap: () => _showEditDialog(item, rawTime),
          leading: Checkbox(
            value: item.isDone,
            activeColor: Colors.blue,
            onChanged: (val) => _firestore.doc(item.id).update({'isDone': val}),
          ),
          title: Text(item.name, style: TextStyle(color: Colors.white, decoration: item.isDone ? TextDecoration.lineThrough : null)),
          subtitle: Text(item.isPending ? "⌛ Syncing..." : "${_formatTimestamp(rawTime)} • Qty: ${item.quantity}", style: TextStyle(color: item.isPending ? Colors.orange : Colors.grey, fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_note, color: Colors.white24, size: 20),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Text(
                  _getInitials(rawData), 
                  style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)
                ),
              ),
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
          Expanded(
            child: TextField(
              controller: _itemController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add item...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1A242E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A242E), borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.remove, color: Colors.blue, size: 18), onPressed: () { if (_quantity > 1) setState(() => _quantity--); }),
                Text("$_quantity", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add, color: Colors.blue, size: 18), onPressed: () => setState(() => _quantity++)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addItem,
            child: const CircleAvatar(backgroundColor: Colors.blue, radius: 22, child: Icon(Icons.arrow_upward, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}