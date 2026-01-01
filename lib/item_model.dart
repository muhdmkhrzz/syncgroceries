class GroceryItem {
  final String id;
  final String name;
  final String description;
  final bool isDone;
  final String userId;

  GroceryItem({
    required this.id,
    required this.name,
    this.description = "",
    this.isDone = false,
    required this.userId,
  });

  factory GroceryItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return GroceryItem(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isDone: map['isDone'] ?? false,
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isDone': isDone,
      'userId': userId,
    };
  }
}