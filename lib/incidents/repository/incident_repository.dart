import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String restaurantId) =>
      _db.collection('restaurants').doc(restaurantId).collection('incidents');

  /// Live stream of all incidents (pending first, then recent).
  Stream<List<IncidentModel>> watchAll(String restaurantId) {
    return _col(restaurantId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .handleError((_) {})
        .map(
          (snap) => snap.docs
              .map((d) => IncidentModel.fromFirestore(d))
              .toList(growable: false),
        );
  }

  /// Live stream of only pending incidents.
  Stream<List<IncidentModel>> watchPending(String restaurantId) {
    return watchAll(restaurantId).map(
      (list) => list
          .where((i) => i.status == IncidentStatus.pending)
          .toList(growable: false),
    );
  }

  Future<void> validate(String restaurantId, String incidentId) =>
      _col(restaurantId).doc(incidentId).update({
        'status': 'validated',
        'updated_at': FieldValue.serverTimestamp(),
      });

  Future<void> ignore(String restaurantId, String incidentId) =>
      _col(restaurantId).doc(incidentId).update({
        'status': 'ignored',
        'updated_at': FieldValue.serverTimestamp(),
      });
}
