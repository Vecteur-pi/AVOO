import 'dart:math';

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

  Future<void> saveTablesCount({
    required String restaurantId,
    required int tablesCount,
  }) async {
    final sanitizedTablesCount = tablesCount < 1 ? 1 : tablesCount;
    final restaurantRef = _restaurants.doc(restaurantId);
    final tablesRef = restaurantRef.collection('tables');

    for (var i = 1; i <= sanitizedTablesCount; i++) {
      final tableId = _tableDocId(i);
      await tablesRef.doc(tableId).set({
        'restaurant_id': restaurantId,
        'restaurantId': restaurantId,
        'table_id': tableId,
        'tableId': tableId,
        'table_number': i,
        'tableNumber': i,
        'label': 'Table $i',
        'capacity': 4,
        'is_active': true,
        'isActive': true,
        'has_qr_code': false,
        'hasQrCode': false,
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final existingTables = await tablesRef.get();
    for (final doc in existingTables.docs) {
      final tableIndex = _tableIndexFromId(doc.id);
      if (tableIndex == null || tableIndex <= sanitizedTablesCount) {
        continue;
      }
      await doc.reference.delete();
    }

    await restaurantRef.set({
      'tables_count': sanitizedTablesCount,
      'tablesCount': sanitizedTablesCount,
      'qr_codes_count': 0,
      'qrCodesCount': 0,
      'qr_generated_at': null,
      'qrGeneratedAt': null,
      'tables_defined_at': FieldValue.serverTimestamp(),
      'tablesDefinedAt': FieldValue.serverTimestamp(),
      'setup_steps': <String, dynamic>{
        'tables_added': true,
        'qr_generated': false,
      },
      'setupSteps': <String, dynamic>{
        'tablesAdded': true,
        'qrGenerated': false,
      },
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAcceptedPaymentMethods({
    required String restaurantId,
    required List<String> methods,
  }) async {
    final sanitizedMethods =
        methods
            .map((method) => method.trim())
            .where((method) => method.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final paymentsEnabled = sanitizedMethods.isNotEmpty;
    await _restaurants.doc(restaurantId).set({
      'accepted_payment_methods': sanitizedMethods,
      'acceptedPaymentMethods': sanitizedMethods,
      'payment_methods': sanitizedMethods,
      'paymentMethods': sanitizedMethods,
      'payments_enabled': paymentsEnabled,
      'paymentsEnabled': paymentsEnabled,
      'payment_modes_updated_at': FieldValue.serverTimestamp(),
      'paymentModesUpdatedAt': FieldValue.serverTimestamp(),
      'setup_steps': <String, dynamic>{'payments_enabled': paymentsEnabled},
      'setupSteps': <String, dynamic>{'paymentsEnabled': paymentsEnabled},
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> generateQRCodesForTables({
    required String restaurantId,
    void Function(int created, int total)? onProgress,
  }) async {
    final restaurantRef = _restaurants.doc(restaurantId);
    final restaurantSnapshot = await restaurantRef.get();
    final restaurantData = restaurantSnapshot.data() ?? <String, dynamic>{};
    final setupSteps = _readMap(restaurantData, const [
      'setup_steps',
      'setupSteps',
    ]);
    final tablesAdded = _readBool(setupSteps, const [
      'tables_added',
      'tablesAdded',
    ]);
    final storedTablesCount =
        _readInt(restaurantData, const ['tables_count', 'tablesCount']) ?? 0;
    if (!tablesAdded || storedTablesCount < 1) {
      throw StateError(
        'Le nombre de tables doit être défini avant la génération des QR codes.',
      );
    }

    final sanitizedTablesCount = storedTablesCount;
    final tablesRef = restaurantRef.collection('tables');
    final random = Random.secure();

    for (var i = 1; i <= sanitizedTablesCount; i++) {
      final tableId = _tableDocId(i);
      final qrToken = _newQrToken(random);
      final qrPayload = Uri(
        scheme: 'avoo',
        host: 'table',
        queryParameters: <String, String>{
          'restaurantId': restaurantId,
          'table': '$i',
          'token': qrToken,
        },
      ).toString();

      await tablesRef.doc(tableId).set({
        'restaurant_id': restaurantId,
        'restaurantId': restaurantId,
        'table_id': tableId,
        'tableId': tableId,
        'table_number': i,
        'tableNumber': i,
        'label': 'Table $i',
        'capacity': 4,
        'is_active': true,
        'isActive': true,
        'has_qr_code': true,
        'hasQrCode': true,
        'qr_payload': qrPayload,
        'qrPayload': qrPayload,
        'qr_token': qrToken,
        'qrToken': qrToken,
        'qr_generated_at': FieldValue.serverTimestamp(),
        'qrGeneratedAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      onProgress?.call(i, sanitizedTablesCount);
    }

    final existingTables = await tablesRef.get();
    for (final doc in existingTables.docs) {
      final tableIndex = _tableIndexFromId(doc.id);
      if (tableIndex == null || tableIndex <= sanitizedTablesCount) {
        continue;
      }
      await doc.reference.delete();
    }

    await restaurantRef.set({
      'tables_count': sanitizedTablesCount,
      'tablesCount': sanitizedTablesCount,
      'qr_codes_count': sanitizedTablesCount,
      'qrCodesCount': sanitizedTablesCount,
      'qr_generated_at': FieldValue.serverTimestamp(),
      'qrGeneratedAt': FieldValue.serverTimestamp(),
      'setup_steps': <String, dynamic>{'qr_generated': true},
      'setupSteps': <String, dynamic>{'qrGenerated': true},
      'updated_at': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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

  String _tableDocId(int tableNumber) {
    return 'table_${tableNumber.toString().padLeft(3, '0')}';
  }

  int? _tableIndexFromId(String tableId) {
    final match = RegExp(r'^table_(\d+)$').firstMatch(tableId);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String _newQrToken(Random random) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  Map<String, dynamic> _readMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return const <String, dynamic>{};
  }

  bool _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
    }
    return false;
  }

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
