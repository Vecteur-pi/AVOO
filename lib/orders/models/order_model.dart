import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  enCours,
  enPreparation,
  pret,
  ingore, // For ignored orders
}

class OrderItem {
  final String name;
  final int quantity;

  OrderItem({
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
    );
  }
}

class OrderModel {
  final String id;
  final String restaurantId;
  final String tableNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int expectedPreparationTimeMinutes; // For "+12 min" calculation

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expectedPreparationTimeMinutes = 20, // Default expectation
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedPreparationTimeMinutes:
          data['expectedPreparationTimeMinutes'] ?? 20,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'items': items.map((e) => e.toMap()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expectedPreparationTimeMinutes': expectedPreparationTimeMinutes,
    };
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'enPreparation':
        return OrderStatus.enPreparation;
      case 'pret':
        return OrderStatus.pret;
      case 'ingore':
        return OrderStatus.ingore;
      case 'enCours':
      default:
        return OrderStatus.enCours;
    }
  }

  OrderModel copyWith({
    String? id,
    String? restaurantId,
    String? tableNumber,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expectedPreparationTimeMinutes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expectedPreparationTimeMinutes:
          expectedPreparationTimeMinutes ?? this.expectedPreparationTimeMinutes,
    );
  }
}
