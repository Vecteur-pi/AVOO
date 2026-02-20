import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart'; // Adjust path if needed

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrdersStream(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ignoreOrder(String orderId) async {
    // Option 1: Delete entirely
    // await _firestore.collection('orders').doc(orderId).delete();

    // Option 2: Mark as ignored (better for history/analytics)
    await updateOrderStatus(orderId, OrderStatus.ingore);
  }
}
