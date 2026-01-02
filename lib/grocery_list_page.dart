import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'item_model.dart';
import 'settings.dart';

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final CollectionReference _firestore = FirebaseFirestore.instance.collection('groceries');
  final TextEditingController _itemController = TextEditingController();
  
  // Minimalist Quantity State
  int _quantity = 1;

  void _addItem() async {
  if (_itemController.text.trim().isNotEmpty) {
    try {
      await _firestore.add({
        'name': _itemController.text.trim(),
        'quantity': _quantity, // Save the current quantity state
        'description': 'Added recently', // Keep your existing text
        'isDone': false,
        'userId': authService.value.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(), 
      });
      
      // Reset state after adding
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Home List", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No item list yet, Add item.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                final items = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return GroceryItem.fromMap(doc.id, data);
                }).toList();

                final toBuy = items.where((i) => !i.isDone).toList();
                final done = items.where((i) => i.isDone).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader("TO BUY"),
                    ...toBuy.map((item) => _buildItemCard(item)),
                    const SizedBox(height: 30),
                    _sectionHeader("DONE"),
                    ...done.map((item) => _buildItemCard(item)),
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

  // FUNCTIONAL: Update quantity in Firestore
void _updateQuantity(String docId, int newQuantity) {
  _firestore.doc(docId).update({'quantity': newQuantity});
}

// UI: Minimalist Edit Dialog
void _showEditQuantityDialog(GroceryItem item) {
  int tempQuantity = item.quantity;

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A242E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Edit Quantity for ${item.name}",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.blue, size: 32),
                      onPressed: () {
                        if (tempQuantity > 1) {
                          setModalState(() => tempQuantity--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "$tempQuantity",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 32),
                      onPressed: () => setModalState(() => tempQuantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () {
                      _updateQuantity(item.id, tempQuantity);
                      Navigator.pop(context);
                    },
                    child: const Text("Update Quantity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildItemCard(GroceryItem item) {
  return Dismissible(
    key: Key(item.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => _deleteItem(item.id),
    background: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isDone ? Colors.transparent : const Color(0xFF1A242E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isDone,
          activeColor: Colors.blue,
          onChanged: (_) => _firestore.doc(item.id).update({'isDone': !item.isDone}),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: Colors.white,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          "${item.description} • Qty: ${item.quantity}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.grey, size: 20),
              onPressed: () => _showEditQuantityDialog(item),
            ),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: const Text("ME", style: TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold)),
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
      decoration: const BoxDecoration(color: Color(0xFF0F1720)),
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A242E),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, color: Colors.blue, size: 18),
                  onPressed: () { if (_quantity > 1) setState(() => _quantity--); },
                ),
                Text("$_quantity", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, color: Colors.blue, size: 18),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addItem,
            child: const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 22,
              child: Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}