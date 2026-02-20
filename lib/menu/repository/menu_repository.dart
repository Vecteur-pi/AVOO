import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../services/public_food_api.dart';

class MenuRepository {
  MenuRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final PublicFoodApi _api = PublicFoodApi();

  /// Watch real-time updates from Firestore for menu items
  Stream<List<MenuItem>> watchMenuItems(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }
  
  /// Add a new item to Firestore
  Future<void> addMenuItem(String restaurantId, MenuItem item) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .add(item.toFirestore());
  }

  /// Delete an item from Firestore
  Future<void> deleteItem(String restaurantId, String itemId) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .doc(itemId)
        .delete();
  }
  
  /// Deactivate an item (force out-of-stock)
  Future<void> deactivateItem(String restaurantId, String itemId) async {
    await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .doc(itemId)
        .update({
      'status': MenuStockStatus.outOfStock.name,
      'quantityRemaining': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  /// Get suggestions from Public API
  Future<List<MenuItem>> searchGeneralKnowledge(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Search both meals and drinks simultaneously
    final results = await Future.wait([
      _api.searchMeals(query),
      _api.searchDrinks(query),
    ]);
    
    return [...results[0], ...results[1]];
  }
}
