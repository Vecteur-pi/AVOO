import 'package:cloud_firestore/cloud_firestore.dart';

import 'owner_setup_state.dart';

enum OwnerSetupStep {
  managerCreated,
  tablesAdded,
  qrGenerated,
  paymentsEnabled,
}

class OwnerSetupService {
  const OwnerSetupService();

  CollectionReference<Map<String, dynamic>> get _restaurants {
    return FirebaseFirestore.instance.collection('restaurants');
  }

  Stream<OwnerSetupState> watch(String restaurantId) {
    return _restaurants
        .doc(restaurantId)
        .snapshots()
        .map(
          (snapshot) => OwnerSetupState.fromData(restaurantId, snapshot.data()),
        );
  }

  Future<void> setStep(
    String restaurantId,
    OwnerSetupStep step,
    bool done,
  ) async {
    final snake = _snakeKey(step);
    final camel = _camelKey(step);
    await _restaurants.doc(restaurantId).set({
      'setup_steps': {snake: done},
      'setupSteps': {camel: done},
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markSetupCompleted(String restaurantId) async {
    await _restaurants.doc(restaurantId).set({
      'setup_completed': true,
      'setupCompleted': true,
      'setup_completed_at': FieldValue.serverTimestamp(),
      'setupCompletedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> assignOwnerAsManager({
    required String restaurantId,
    required String ownerUid,
    required String ownerName,
    String? ownerEmail,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _restaurants.doc(restaurantId).set({
      'manager_choice': 'self',
      'managerChoice': 'self',
      'owner_is_manager': true,
      'ownerIsManager': true,
      'manager_profile': <String, dynamic>{
        'uid': ownerUid,
        'name': ownerName,
        'email': ownerEmail ?? '',
        'role': 'owner_manager',
        'source': 'owner',
      },
      'managerProfile': <String, dynamic>{
        'uid': ownerUid,
        'name': ownerName,
        'email': ownerEmail ?? '',
        'role': 'owner_manager',
        'source': 'owner',
      },
      'setup_steps': <String, dynamic>{'manager_created': true},
      'setupSteps': <String, dynamic>{'managerCreated': true},
      'updated_at': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> saveManagerInvitation({
    required String restaurantId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _restaurants.doc(restaurantId).set({
      'manager_choice': 'appointed',
      'managerChoice': 'appointed',
      'owner_is_manager': false,
      'ownerIsManager': false,
      'manager_invitation': <String, dynamic>{
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'status': 'pending',
        'created_at': now,
        'updated_at': now,
      },
      'managerInvitation': <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      },
      'setup_steps': <String, dynamic>{'manager_created': true},
      'setupSteps': <String, dynamic>{'managerCreated': true},
      'updated_at': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  String _snakeKey(OwnerSetupStep step) {
    switch (step) {
      case OwnerSetupStep.managerCreated:
        return 'manager_created';
      case OwnerSetupStep.tablesAdded:
        return 'tables_added';
      case OwnerSetupStep.qrGenerated:
        return 'qr_generated';
      case OwnerSetupStep.paymentsEnabled:
        return 'payments_enabled';
    }
  }

  String _camelKey(OwnerSetupStep step) {
    switch (step) {
      case OwnerSetupStep.managerCreated:
        return 'managerCreated';
      case OwnerSetupStep.tablesAdded:
        return 'tablesAdded';
      case OwnerSetupStep.qrGenerated:
        return 'qrGenerated';
      case OwnerSetupStep.paymentsEnabled:
        return 'paymentsEnabled';
    }
  }
}
