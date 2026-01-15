class GroceryItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final bool isDone;
  final String userId;
  final bool isPending; 

  GroceryItem({
    required this.id,
    required this.name,
    this.description = "",
    required this.quantity,
    this.isDone = false,
    required this.userId,
    this.isPending = false, 
  });

  factory GroceryItem.fromMap(String id, Map<String, dynamic> map, {bool isPending = false}) {
    return GroceryItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      isDone: map['isDone'] ?? false,
      userId: map['userId'] ?? '',
      isPending: isPending, 
    );
  }
}