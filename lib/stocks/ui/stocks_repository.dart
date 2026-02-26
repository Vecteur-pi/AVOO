import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_product.dart';

abstract class StocksRepositoryBase {
  Stream<List<StockProduct>> watchStocks(String restaurantId);

  Future<void> createStockItem({
    required String restaurantId,
    required String name,
    required String category,
    required double initialQuantity,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  });

  Future<void> addStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantityToAdd,
  });

  Future<void> updateStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantity,
  });

  Future<void> archiveStockItem({
    required String restaurantId,
    required String itemId,
  });

  Future<void> restoreStockItem({
    required String restaurantId,
    required String itemId,
  });
  Future<void> updateStockItem({
    required String restaurantId,
    required String itemId,
    required String name,
    required double quantity,
    required String category,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  });

  Future<void> deleteStockItem({
    required String restaurantId,
    required String itemId,
  });
}

class StocksRepository implements StocksRepositoryBase {
  StocksRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<StockProduct>> watchStocks(String restaurantId) {
    // We listen to multiple collections to support various schemas,
    // prioritizing the first one that yields results, but for simplicity
    // in UI we map one unified stream. The OwnerDashboard expects
    // 'inventory', 'products', 'stocks', 'items' under restaurants.

    // We will listen specifically to 'inventory' for demonstration,
    // which is standard for stock features.
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => _parseStockProduct(doc)).toList();
        });
  }

  @override
  Future<void> createStockItem({
    required String restaurantId,
    required String name,
    required String category,
    required double initialQuantity,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Le nom du produit est obligatoire.');
    }

    final now = FieldValue.serverTimestamp();
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .add({
          'name': trimmedName,
          'category': category.trim().isEmpty ? 'Nourritures' : category.trim(),
          'stock': initialQuantity,
          'unit': unit.trim().isEmpty ? 'unités' : unit.trim(),
          'min_stock': minStock,
          'description': shortDescription?.trim() ?? '',
          'purchase_price': purchasePrice,
          'supplier': supplier?.trim() ?? '',
          'location': location?.trim() ?? '',
          'perishable': perishable,
          'expires_at': perishable && expiresAt != null
              ? Timestamp.fromDate(expiresAt)
              : null,
          'active': true,
          'created_at': now,
          'updated_at': now,
        });
  }

  @override
  Future<void> addStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantityToAdd,
  }) async {
    if (quantityToAdd <= 0) {
      throw ArgumentError('La quantité doit être supérieure à 0.');
    }

    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .set({
          'stock': FieldValue.increment(quantityToAdd),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> updateStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantity,
  }) async {
    if (quantity < 0) {
      throw ArgumentError('La quantité ne peut pas être négative.');
    }

    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .set({
          'stock': quantity,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> archiveStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .set({
          'active': false,
          'archived': true,
          'archived_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> restoreStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .set({
          'active': true,
          'archived': false,
          'archived_at': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> updateStockItem({
    required String restaurantId,
    required String itemId,
    required String name,
    required double quantity,
    required String category,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Le nom du produit est obligatoire.');
    }
    if (quantity < 0) {
      throw ArgumentError('La quantité ne peut pas être négative.');
    }

    final now = FieldValue.serverTimestamp();
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .set({
          'name': trimmedName,
          'category': category.trim().isEmpty ? 'Nourritures' : category.trim(),
          'stock': quantity,
          'unit': unit.trim().isEmpty ? 'unités' : unit.trim(),
          'min_stock': minStock,
          'description': shortDescription?.trim() ?? '',
          'purchase_price': purchasePrice,
          'supplier': supplier?.trim() ?? '',
          'location': location?.trim() ?? '',
          'perishable': perishable,
          'expires_at': perishable && expiresAt != null
              ? Timestamp.fromDate(expiresAt)
              : null,
          'updated_at': now,
        }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('inventory')
        .doc(itemId)
        .delete();
  }

  StockProduct _parseStockProduct(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final id = doc.id;

    final name = _readString(data, const [
      'name',
      'product_name',
      'productName',
      'item_name',
      'itemName',
      'title',
      'label',
    ]);

    final categoryName = _readString(data, const ['category', 'type', 'group']);

    // Determine category based on name or fallback.
    var stockCategory = categoryName.toLowerCase().contains('boisson')
        ? const StockCategory(id: 'cat_boissons', name: 'Boissons')
        : const StockCategory(id: 'cat_nourritures', name: 'Nourritures');

    if (categoryName.isEmpty) {
      // Default to nourritures if no category found
      stockCategory = const StockCategory(
        id: 'cat_nourritures',
        name: 'Nourritures',
      );
    } else if (categoryName.isNotEmpty &&
        !categoryName.toLowerCase().contains('boisson') &&
        !categoryName.toLowerCase().contains('nourriture')) {
      // If it has a specific category name from DB, use it
      stockCategory = StockCategory(
        id: categoryName.toLowerCase(),
        name: categoryName,
      );
    }

    final quantity =
        _readDouble(data, const [
          'stock',
          'stock_quantity',
          'stockQuantity',
          'quantity',
          'qty',
          'remaining',
          'current_stock',
          'currentStock',
        ]) ??
        0;

    final unit = _readString(data, const ['unit', 'units', 'measure']);

    final active = _readBool(data, const ['active', 'is_active', 'isActive']);
    final explicitArchived = _readBool(data, const [
      'archived',
      'is_archived',
      'isArchived',
    ]);
    final hasArchivedAt =
        _readDate(data, const ['archived_at', 'archivedAt', 'deleted_at']) !=
        null;
    final isArchived =
        explicitArchived == true || hasArchivedAt || active == false;

    final minStock =
        _readDouble(data, const [
          'min_stock',
          'minStock',
          'alert_threshold',
          'alertThreshold',
          'reorder_level',
          'reorderLevel',
          'minimum',
        ]) ??
        5; // Default threshold

    StockStatus status;
    if (quantity <= 0) {
      status = StockStatus.critical;
    } else if (quantity <= minStock) {
      status = StockStatus.low;
    } else {
      status = StockStatus.normal;
    }

    // Attempt to read usage
    final usageToday = _readDouble(data, const [
      'usage_today',
      'usageToday',
      'sold_today',
      'soldToday',
    ]);
    final usageUnit = _readString(data, const ['usage_unit', 'usageUnit']);

    // Attempt to read date
    final lastUpdated =
        _readDate(data, const [
          'updated_at',
          'updatedAt',
          'last_modified',
          'lastModified',
        ]) ??
        DateTime.now();

    final description = _readString(data, const [
      'description',
      'shortDescription',
      'short_description',
    ]);
    final purchasePrice = _readDouble(data, const [
      'purchase_price',
      'purchasePrice',
      'price',
    ]);
    final supplier = _readString(data, const ['supplier', 'vendor']);
    final location = _readString(data, const [
      'location',
      'shelf',
      'emplacement',
    ]);
    final perishable =
        _readBool(data, const [
          'perishable',
          'isPerishable',
          'is_perishable',
        ]) ??
        false;
    final expiresAt = _readDate(data, const [
      'expires_at',
      'expiresAt',
      'expiry',
      'expiry_date',
    ]);

    return StockProduct(
      id: id,
      name: name.isEmpty ? 'Produit inconnu' : name,
      category: stockCategory,
      quantityRemaining: quantity,
      unit: unit.isEmpty ? 'unités' : unit,
      status: status,
      isArchived: isArchived,
      minStock: minStock,
      usageToday: usageToday,
      usageUnit: usageUnit,
      description: description,
      purchasePrice: purchasePrice,
      supplier: supplier,
      location: location,
      perishable: perishable,
      expiresAt: expiresAt,
      lastUpdated: lastUpdated,
    );
  }

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
