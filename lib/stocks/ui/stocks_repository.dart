import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_product.dart';

class StocksRepository {
  StocksRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      'label'
    ]);

    final categoryName = _readString(data, const [
      'category',
      'type',
      'group'
    ]);
    
    // Determine category based on name or fallback.
    var stockCategory = categoryName.toLowerCase().contains('boisson') 
        ? const StockCategory(id: 'cat_boissons', name: 'Boissons')
        : const StockCategory(id: 'cat_nourritures', name: 'Nourritures');
        
    if (categoryName.isEmpty) {
      // Default to nourritures if no category found
      stockCategory = const StockCategory(id: 'cat_nourritures', name: 'Nourritures');
    } else if (categoryName.isNotEmpty && !categoryName.toLowerCase().contains('boisson') && !categoryName.toLowerCase().contains('nourriture')) {
       // If it has a specific category name from DB, use it
       stockCategory = StockCategory(id: categoryName.toLowerCase(), name: categoryName);
    }

    final quantity = _readDouble(data, const [
      'stock',
      'stock_quantity',
      'stockQuantity',
      'quantity',
      'qty',
      'remaining',
      'current_stock',
      'currentStock',
    ]) ?? 0;

    final unit = _readString(data, const [
      'unit',
      'units',
      'measure'
    ]);

    final minStock = _readDouble(data, const [
      'min_stock',
      'minStock',
      'alert_threshold',
      'alertThreshold',
      'reorder_level',
      'reorderLevel',
      'minimum',
    ]) ?? 5; // Default threshold

    StockStatus status;
    if (quantity <= 0) {
      status = StockStatus.critical;
    } else if (quantity <= minStock) {
      status = StockStatus.low;
    } else {
      status = StockStatus.normal;
    }

    // Attempt to read usage
    final usageToday = _readDouble(data, const ['usage_today', 'usageToday', 'sold_today', 'soldToday']);
    final usageUnit = _readString(data, const ['usage_unit', 'usageUnit']);

    // Attempt to read date
    final lastUpdated = _readDate(data, const ['updated_at', 'updatedAt', 'last_modified', 'lastModified']) ?? DateTime.now();

    return StockProduct(
      id: id,
      name: name.isEmpty ? 'Produit inconnu' : name,
      category: stockCategory,
      quantityRemaining: quantity,
      unit: unit.isEmpty ? 'unités' : unit,
      status: status,
      usageToday: usageToday,
      usageUnit: usageUnit,
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
