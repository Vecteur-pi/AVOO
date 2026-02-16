class OwnerSetupState {
  const OwnerSetupState({
    required this.restaurantId,
    required this.restaurantName,
    required this.tablesCount,
    required this.paymentMethods,
    required this.managerCreated,
    required this.tablesAdded,
    required this.qrGenerated,
    required this.paymentsEnabled,
    required this.setupCompleted,
  });

  final String restaurantId;
  final String restaurantName;
  final int? tablesCount;
  final List<String> paymentMethods;
  final bool managerCreated;
  final bool tablesAdded;
  final bool qrGenerated;
  final bool paymentsEnabled;
  final bool setupCompleted;

  static OwnerSetupState initial(String restaurantId) {
    return OwnerSetupState(
      restaurantId: restaurantId,
      restaurantName: 'Votre restaurant',
      tablesCount: null,
      paymentMethods: const <String>[],
      managerCreated: false,
      tablesAdded: false,
      qrGenerated: false,
      paymentsEnabled: false,
      setupCompleted: false,
    );
  }

  factory OwnerSetupState.fromData(
    String restaurantId,
    Map<String, dynamic>? data,
  ) {
    final map = data ?? <String, dynamic>{};
    final setupStepsRaw = _readMap(map, const ['setup_steps', 'setupSteps']);
    final tablesCount = _readInt(map, const ['tables_count', 'tablesCount']);
    final paymentMethods = _readStringList(map, const [
      'accepted_payment_methods',
      'acceptedPaymentMethods',
      'payment_methods',
      'paymentMethods',
    ]);

    final managerCreated = _readBool(setupStepsRaw, const [
      'manager_created',
      'managerCreated',
    ]);
    final tablesAdded = _readBool(setupStepsRaw, const [
      'tables_added',
      'tablesAdded',
    ]);
    final qrGenerated = _readBool(setupStepsRaw, const [
      'qr_generated',
      'qrGenerated',
    ]);
    final paymentsEnabled =
        _readBool(setupStepsRaw, const [
          'payments_enabled',
          'paymentsEnabled',
        ]) ||
        paymentMethods.isNotEmpty;

    final setupCompleted =
        _readBool(map, const ['setup_completed', 'setupCompleted']) ||
        (managerCreated && tablesAdded && qrGenerated && paymentsEnabled);

    return OwnerSetupState(
      restaurantId: restaurantId,
      restaurantName: _readString(map, const [
        'name',
        'restaurant_name',
        'restaurantName',
      ], fallback: 'Votre restaurant'),
      tablesCount: tablesCount,
      paymentMethods: paymentMethods,
      managerCreated: managerCreated,
      tablesAdded: tablesAdded,
      qrGenerated: qrGenerated,
      paymentsEnabled: paymentsEnabled,
      setupCompleted: setupCompleted,
    );
  }

  int get completedStepsCount {
    return [
      managerCreated,
      tablesAdded,
      qrGenerated,
      paymentsEnabled,
    ].where((done) => done).length;
  }

  bool get requiredStepsCompleted {
    return managerCreated && tablesAdded && qrGenerated && paymentsEnabled;
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
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

  static bool _readBool(Map<String, dynamic> data, List<String> keys) {
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

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
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

  static List<String> _readStringList(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        final parsed =
            value
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        return parsed;
      }
    }
    return const <String>[];
  }
}
