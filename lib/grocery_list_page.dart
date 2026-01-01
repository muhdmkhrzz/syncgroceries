import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';
import 'item_model.dart';

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  final _database = FirebaseDatabase.instance.ref().child('groceries');
  final _itemController = TextEditingController();

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      _database.push().set({
        'name': _itemController.text,
        'description': 'Added recently',
        'isDone': false,
        'userId': authService.value.currentUser?.uid,
      });
      _itemController.clear();
    }
  }

  void _toggleItem(GroceryItem item) {
    _database.child(item.id).update({'isDone': !item.isDone});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Home List", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => authService.value.signOut(), icon: const Icon(Icons.logout)),
          const Icon(Icons.settings),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _database.onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("List is empty"));
                }

                Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
                List<GroceryItem> items = data.entries.map((e) => GroceryItem.fromMap(e.key, e.value)).toList();

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
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildItemCard(GroceryItem item) {
    return Container(
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
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(item.name, style: TextStyle(decoration: item.isDone ? TextDecoration.lineThrough : null)),
        subtitle: Text(item.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: const Text("ME", style: TextStyle(fontSize: 8, color: Colors.blue)),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF0F1720)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              decoration: InputDecoration(
                hintText: "Add item (e.g., Milk)...",
                filled: true,
                fillColor: const Color(0xFF1A242E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _addItem,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          )
        ],
      ),
    );
  }
}