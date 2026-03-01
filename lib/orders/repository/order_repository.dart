import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart'; // Adjust path if needed
import '../models/table_dashboard_models.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> getOrdersStream(String restaurantId) {
    final streams = <Stream<QuerySnapshot<Map<String, dynamic>>>>[
      _firestore
          .collection('orders')
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots(),
      _firestore
          .collection('orders')
          .where('restaurant_id', isEqualTo: restaurantId)
          .snapshots(),
    ];
    return _mergeOrderStreams(streams);
  }

  Stream<List<OrderModel>> _mergeOrderStreams(
    List<Stream<QuerySnapshot<Map<String, dynamic>>>> streams,
  ) {
    final controller = StreamController<List<OrderModel>>();
    final latestSnapshots = List<QuerySnapshot<Map<String, dynamic>>?>.filled(
      streams.length,
      null,
    );
    final subscriptions =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitMerged() {
      final deduped = <String, OrderModel>{};
      for (final snapshot in latestSnapshots) {
        if (snapshot == null) continue;
        for (final doc in snapshot.docs) {
          try {
            deduped[doc.id] = OrderModel.fromFirestore(doc);
          } catch (_) {
            // Ignore malformed docs to keep stream resilient.
          }
        }
      }

      final merged = deduped.values.toList(growable: false)
        ..sort((a, b) {
          final updated = b.updatedAt.compareTo(a.updatedAt);
          if (updated != 0) return updated;
          return b.createdAt.compareTo(a.createdAt);
        });
      controller.add(merged);
    }

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      final subscription = streams[i].listen(
        (snapshot) {
          latestSnapshots[index] = snapshot;
          emitMerged();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            // Keep the dashboard usable even if one schema query is denied.
            latestSnapshots[index] = null;
            emitMerged();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );
      subscriptions.add(subscription);
    }

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await controller.close();
    };

    return controller.stream;
  }

  Stream<List<OrderModel>> getPrimaryOrdersOnly(String restaurantId) {
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

  Future<void> updateTableStatus({
    required String restaurantId,
    required String tableId,
    required TableState tableState,
    required TableServicePhase servicePhase,
  }) async {
    final now = FieldValue.serverTimestamp();
    final statusValue = _statusFor(
      tableState: tableState,
      servicePhase: servicePhase,
    );
    final fullUpdate = <String, dynamic>{
      'table_state': tableState.name,
      'tableState': tableState.name,
      'service_phase': servicePhase.name,
      'servicePhase': servicePhase.name,
      'status': statusValue,
      'active_ticket_status': servicePhase.name,
      'updated_at': now,
      'updatedAt': now,
    };

    if (servicePhase == TableServicePhase.none) {
      fullUpdate['phase_started_at'] = null;
      fullUpdate['phaseStartedAt'] = null;
    } else {
      fullUpdate['phase_started_at'] = now;
      fullUpdate['phaseStartedAt'] = now;
    }

    final clearsTicket =
        tableState == TableState.free ||
        tableState == TableState.reserved ||
        tableState == TableState.unavailable;
    if (clearsTicket) {
      fullUpdate['guest_count'] = 0;
      fullUpdate['guestCount'] = 0;
      fullUpdate['active_ticket_id'] = '';
      fullUpdate['activeTicketId'] = '';
      fullUpdate['active_ticket_total'] = 0;
      fullUpdate['activeTicketTotal'] = 0;
    }

    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .set(fullUpdate, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }

      // Fallback for waiter-like roles restricted to a small key set by rules.
      final restrictedUpdate = <String, dynamic>{
        'status': statusValue,
        'active_ticket_status': servicePhase.name,
        'updated_at': now,
      };
      if (clearsTicket) {
        restrictedUpdate['active_ticket_id'] = '';
      }

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('tables')
          .doc(tableId)
          .set(restrictedUpdate, SetOptions(merge: true));
    }
  }

  String _statusFor({
    required TableState tableState,
    required TableServicePhase servicePhase,
  }) {
    if (servicePhase != TableServicePhase.none) {
      return servicePhase.name;
    }
    switch (tableState) {
      case TableState.free:
        return 'free';
      case TableState.occupied:
        return 'occupied';
      case TableState.reserved:
        return 'reserved';
      case TableState.cleaning:
        return 'cleaning';
      case TableState.unavailable:
        return 'unavailable';
    }
  }
}
