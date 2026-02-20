import 'package:cloud_firestore/cloud_firestore.dart';

enum MenuCategory {
  food,
  drink,
}

enum MenuStockStatus {
  normal,
  low,
  outOfStock,
}

class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.quantityRemaining,
    required this.status,
    required this.lastUpdated,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final MenuCategory category;
  final int quantityRemaining;
  final MenuStockStatus status;
  final DateTime lastUpdated;

  factory MenuItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Parse category
    final catStr = data['category'] as String? ?? 'food';
    final category = catStr == 'drink' ? MenuCategory.drink : MenuCategory.food;
    
    // Parse status
    final statusStr = data['status'] as String? ?? 'normal';
    MenuStockStatus status;
    switch (statusStr) {
      case 'low':
        status = MenuStockStatus.low;
        break;
      case 'outOfStock':
      case 'out_of_stock':
        status = MenuStockStatus.outOfStock;
        break;
      default:
        status = MenuStockStatus.normal;
    }

    // Parse date
    DateTime updated = DateTime.now();
    if (data['lastUpdated'] is Timestamp) {
      updated = (data['lastUpdated'] as Timestamp).toDate();
    } else if (data['updated_at'] is Timestamp) {
      updated = (data['updated_at'] as Timestamp).toDate();
    }

    return MenuItem(
      id: doc.id,
      name: data['name'] ?? 'Inconnu',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      category: category,
      quantityRemaining: data['quantityRemaining'] ?? data['quantity'] ?? 0,
      status: status,
      lastUpdated: updated,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category.name,
      'quantityRemaining': quantityRemaining,
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    MenuCategory? category,
    int? quantityRemaining,
    MenuStockStatus? status,
    DateTime? lastUpdated,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
