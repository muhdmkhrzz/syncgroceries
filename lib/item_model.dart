class GroceryItem {
  final String id;
  final String name;
  final String description;
  final int quantity; // Add this field
  final bool isDone;
  final String userId;

  GroceryItem({
    required this.id,
    required this.name,
    this.description = "",
    required this.quantity, // Add this
    this.isDone = false,
    required this.userId,
  });

  factory GroceryItem.fromMap(String id, Map<String, dynamic> map) {
    return GroceryItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1, // Default to 1 if missing
      isDone: map['isDone'] ?? false,
      userId: map['userId'] ?? '',
    );
  }
}