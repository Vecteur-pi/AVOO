import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  enCours,
  enPreparation,
  pret,
  servie,
  payee,
  fermee,
  ingore, // For ignored orders
}

class OrderItem {
  final String name;
  final int quantity;

  OrderItem({required this.name, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity};
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
  final double totalAmount;
  final int expectedPreparationTimeMinutes; // For "+12 min" calculation

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmount,
    this.expectedPreparationTimeMinutes = 20, // Default expectation
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      restaurantId: _readRestaurantId(data),
      tableNumber: _readTableNumber(data),
      items:
          (data['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: _parseStatus(data['status']?.toString()),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: _readAmount(data),
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
      'totalAmount': totalAmount,
      'expectedPreparationTimeMinutes': expectedPreparationTimeMinutes,
    };
  }

  static OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'enPreparation':
        return OrderStatus.enPreparation;
      case 'pret':
        return OrderStatus.pret;
      case 'servie':
      case 'servi':
      case 'served':
        return OrderStatus.servie;
      case 'payee':
      case 'paye':
      case 'paid':
      case 'settled':
      case 'encaissee':
      case 'encaisseee':
        return OrderStatus.payee;
      case 'fermee':
      case 'ferme':
      case 'closed':
      case 'close':
        return OrderStatus.fermee;
      case 'ingore':
        return OrderStatus.ingore;
      case 'enCours':
      default:
        return OrderStatus.enCours;
    }
  }

  static String _readRestaurantId(Map<String, dynamic> data) {
    for (final key in const ['restaurantId', 'restaurant_id', 'restaurant']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String _readTableNumber(Map<String, dynamic> data) {
    final raw = _firstValue(data, const [
      'tableNumber',
      'table_number',
      'table',
      'tableLabel',
      'table_label',
      'tableName',
      'table_name',
      'tableId',
      'table_id',
    ]);

    final value = _asCleanString(raw);
    if (value.isEmpty) {
      return '';
    }

    final tableIdMatch = RegExp(
      r'^table[_\-\s]*0*(\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (tableIdMatch != null) {
      return tableIdMatch.group(1)!;
    }

    final tableMatch = RegExp(
      r'^table[\s:_-]*t?\s*0*(\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (tableMatch != null) {
      return tableMatch.group(1)!;
    }

    final tMatch = RegExp(
      r'^t\s*0*(\d+)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (tMatch != null) {
      return tMatch.group(1)!;
    }

    final numericMatch = RegExp(r'^0*(\d+)$').firstMatch(value);
    if (numericMatch != null) {
      return numericMatch.group(1)!;
    }

    return value;
  }

  static double _readAmount(Map<String, dynamic> data) {
    for (final key in const [
      'totalAmount',
      'total_amount',
      'total',
      'amount',
      'paidAmount',
      'paid_amount',
      'grandTotal',
      'grand_total',
    ]) {
      final raw = data[key];
      if (raw is num) {
        return raw.toDouble();
      }
      if (raw is String) {
        final cleaned = raw
            .replaceAll('\u00A0', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9.\-]'), '');
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static dynamic _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      return value;
    }
    return null;
  }

  static String _asCleanString(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value.trim();
    }
    if (value is int) {
      return value.toString();
    }
    if (value is num) {
      final asInt = value.toInt();
      if (value == asInt) {
        return asInt.toString();
      }
      return value.toString();
    }
    return value.toString().trim();
  }

  OrderModel copyWith({
    String? id,
    String? restaurantId,
    String? tableNumber,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalAmount,
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
      totalAmount: totalAmount ?? this.totalAmount,
      expectedPreparationTimeMinutes:
          expectedPreparationTimeMinutes ?? this.expectedPreparationTimeMinutes,
    );
  }
}
