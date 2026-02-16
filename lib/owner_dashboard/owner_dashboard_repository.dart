import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerDashboardData {
  const OwnerDashboardData({
    required this.dailySales,
    required this.yesterdaySales,
    required this.dailyTickets,
    required this.averageTicket,
    required this.pendingIncidents,
    required this.lowStockProducts,
    required this.hourlyLabels,
    required this.hourlySales,
    required this.topProducts,
  });

  final double dailySales;
  final double yesterdaySales;
  final int dailyTickets;
  final double averageTicket;
  final int pendingIncidents;
  final int lowStockProducts;
  final List<String> hourlyLabels;
  final List<double> hourlySales;
  final List<TopProductData> topProducts;

  double get salesChangePercent {
    if (yesterdaySales <= 0) {
      return dailySales <= 0 ? 0 : 100;
    }
    return ((dailySales - yesterdaySales) / yesterdaySales) * 100;
  }

  factory OwnerDashboardData.empty() {
    return const OwnerDashboardData(
      dailySales: 0,
      yesterdaySales: 0,
      dailyTickets: 0,
      averageTicket: 0,
      pendingIncidents: 0,
      lowStockProducts: 0,
      hourlyLabels: [
        '8h',
        '9h',
        '10h',
        '11h',
        '12h',
        '13h',
        '14h',
        '15h',
        '16h',
        '17h',
      ],
      hourlySales: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      topProducts: [],
    );
  }
}

class TopProductData {
  const TopProductData({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.growthPercent,
  });

  final String name;
  final int quantity;
  final double revenue;
  final double growthPercent;
}

class OwnerDashboardRepository {
  OwnerDashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<OwnerDashboardData> watch(String restaurantId) async* {
    while (true) {
      try {
        yield await load(restaurantId);
      } catch (_) {
        yield OwnerDashboardData.empty();
      }
      await Future<void>.delayed(const Duration(seconds: 20));
    }
  }

  Future<OwnerDashboardData> load(String restaurantId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final docs = await Future.wait<List<_FirestoreRecord>>([
      _loadOrderLikeDocs(restaurantId),
      _loadIncidentDocs(restaurantId),
      _loadStockDocs(restaurantId),
    ]);

    final orderEntries = docs[0]
        .map(_toOrderEntry)
        .whereType<_OrderEntry>()
        .toList(growable: false);

    double dailySales = 0;
    double yesterdaySales = 0;
    int dailyTickets = 0;

    const hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
    final hourlySales = List<double>.filled(hours.length, 0);

    final todayProducts = <String, _ProductAccumulator>{};
    final yesterdayProducts = <String, _ProductAccumulator>{};

    for (final order in orderEntries) {
      if (_isWithinRange(order.createdAt, todayStart, now)) {
        dailySales += order.amount;
        dailyTickets += 1;
        final hour = order.createdAt.hour;
        if (hour >= hours.first && hour <= hours.last) {
          hourlySales[hour - hours.first] += order.amount;
        }
        _accumulateProducts(todayProducts, order.items);
      } else if (_isWithinRange(order.createdAt, yesterdayStart, todayStart)) {
        yesterdaySales += order.amount;
        _accumulateProducts(yesterdayProducts, order.items);
      }
    }

    final averageTicket = dailyTickets == 0 ? 0.0 : dailySales / dailyTickets;

    var pendingIncidents = 0;
    for (final incident in docs[1]) {
      if (_isPendingIncident(incident.data)) {
        pendingIncidents += 1;
      }
    }

    var lowStockProducts = 0;
    for (final product in docs[2]) {
      if (_isLowStock(product.data)) {
        lowStockProducts += 1;
      }
    }

    final topProducts = _buildTopProducts(todayProducts, yesterdayProducts);

    return OwnerDashboardData(
      dailySales: dailySales,
      yesterdaySales: yesterdaySales,
      dailyTickets: dailyTickets,
      averageTicket: averageTicket,
      pendingIncidents: pendingIncidents,
      lowStockProducts: lowStockProducts,
      hourlyLabels: hours.map((hour) => '${hour}h').toList(growable: false),
      hourlySales: hourlySales,
      topProducts: topProducts,
    );
  }

  Future<List<_FirestoreRecord>> _loadOrderLikeDocs(String restaurantId) async {
    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(restaurantId);

    final queries = <Query<Map<String, dynamic>>>[
      restaurantRef.collection('orders').limit(800),
      restaurantRef.collection('tickets').limit(800),
      restaurantRef.collection('sales').limit(800),
      restaurantRef.collection('transactions').limit(800),
      restaurantRef.collection('payments').limit(800),
      ..._scopedRootQueries('orders', restaurantId),
      ..._scopedRootQueries('tickets', restaurantId),
      ..._scopedRootQueries('sales', restaurantId),
      ..._scopedRootQueries('transactions', restaurantId),
      ..._scopedRootQueries('payments', restaurantId),
    ];

    return _fetchDeduped(queries);
  }

  Future<List<_FirestoreRecord>> _loadIncidentDocs(String restaurantId) async {
    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(restaurantId);

    final queries = <Query<Map<String, dynamic>>>[
      restaurantRef.collection('incidents').limit(500),
      restaurantRef.collection('alerts').limit(500),
      restaurantRef.collection('reports').limit(500),
      ..._scopedRootQueries('incidents', restaurantId),
      ..._scopedRootQueries('alerts', restaurantId),
      ..._scopedRootQueries('reports', restaurantId),
    ];

    return _fetchDeduped(queries);
  }

  Future<List<_FirestoreRecord>> _loadStockDocs(String restaurantId) async {
    final restaurantRef = _firestore
        .collection('restaurants')
        .doc(restaurantId);

    final queries = <Query<Map<String, dynamic>>>[
      restaurantRef.collection('products').limit(1000),
      restaurantRef.collection('stocks').limit(1000),
      restaurantRef.collection('inventory').limit(1000),
      restaurantRef.collection('items').limit(1000),
      ..._scopedRootQueries('products', restaurantId),
      ..._scopedRootQueries('stocks', restaurantId),
      ..._scopedRootQueries('inventory', restaurantId),
      ..._scopedRootQueries('items', restaurantId),
    ];

    return _fetchDeduped(queries);
  }

  List<Query<Map<String, dynamic>>> _scopedRootQueries(
    String collection,
    String restaurantId,
  ) {
    return [
      _firestore
          .collection(collection)
          .where('restaurant_id', isEqualTo: restaurantId)
          .limit(800),
      _firestore
          .collection(collection)
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(800),
      _firestore
          .collection(collection)
          .where('restaurant', isEqualTo: restaurantId)
          .limit(800),
    ];
  }

  Future<List<_FirestoreRecord>> _fetchDeduped(
    List<Query<Map<String, dynamic>>> queries,
  ) async {
    final batches = await Future.wait<List<_FirestoreRecord>>(
      queries.map(_safeFetch),
    );

    final deduped = <String, _FirestoreRecord>{};
    for (final batch in batches) {
      for (final record in batch) {
        deduped[record.path] = record;
      }
    }
    return deduped.values.toList(growable: false);
  }

  Future<List<_FirestoreRecord>> _safeFetch(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => _FirestoreRecord(
              id: doc.id,
              path: doc.reference.path,
              data: doc.data(),
            ),
          )
          .toList(growable: false);
    } on FirebaseException {
      return const <_FirestoreRecord>[];
    } catch (_) {
      return const <_FirestoreRecord>[];
    }
  }

  _OrderEntry? _toOrderEntry(_FirestoreRecord record) {
    final data = record.data;
    final createdAt = _readDate(data, const [
      'created_at',
      'createdAt',
      'timestamp',
      'date',
      'ordered_at',
      'orderedAt',
      'paid_at',
      'paidAt',
      'updated_at',
      'updatedAt',
    ]);
    if (createdAt == null) {
      return null;
    }

    final status = _readString(data, const [
      'status',
      'state',
      'order_status',
      'orderStatus',
      'payment_status',
      'paymentStatus',
    ]).toLowerCase();
    if (_isCancelledStatus(status)) {
      return null;
    }

    final items = _extractOrderItems(data);

    var amount =
        _readDouble(data, const [
          'total',
          'total_amount',
          'totalAmount',
          'amount',
          'paid_amount',
          'paidAmount',
          'grand_total',
          'grandTotal',
          'net_total',
          'netTotal',
        ]) ??
        0;

    if (amount <= 0 && items.isNotEmpty) {
      amount = items.fold<double>(0, (sum, item) => sum + item.amount);
    }

    if (amount < 0) {
      amount = 0;
    }

    return _OrderEntry(createdAt: createdAt, amount: amount, items: items);
  }

  bool _isCancelledStatus(String status) {
    if (status.isEmpty) return false;
    return status.contains('cancel') ||
        status.contains('annul') ||
        status.contains('refund') ||
        status.contains('reject') ||
        status.contains('failed') ||
        status.contains('void') ||
        status.contains('draft');
  }

  List<_SoldItem> _extractOrderItems(Map<String, dynamic> data) {
    for (final key in const [
      'items',
      'order_items',
      'orderItems',
      'lines',
      'products',
      'details',
    ]) {
      final raw = data[key];
      if (raw is List) {
        final items = <_SoldItem>[];
        for (final entry in raw) {
          final map = _toStringMap(entry);
          if (map == null) continue;
          final name = _readString(map, const [
            'name',
            'product_name',
            'productName',
            'item_name',
            'itemName',
            'menu_name',
            'menuName',
            'title',
            'label',
          ]);
          if (name.isEmpty) continue;

          final quantity =
              (_readDouble(map, const ['quantity', 'qty', 'count', 'units']) ??
                      1)
                  .round();

          var total = _readDouble(map, const [
            'total',
            'total_amount',
            'totalAmount',
            'line_total',
            'lineTotal',
            'amount',
            'subtotal',
          ]);

          total ??=
              (_readDouble(map, const ['price', 'unit_price', 'unitPrice']) ??
                  0) *
              (quantity <= 0 ? 1 : quantity);

          items.add(
            _SoldItem(
              name: name,
              quantity: quantity <= 0 ? 1 : quantity,
              amount: total,
            ),
          );
        }

        if (items.isNotEmpty) {
          return items;
        }
      }
    }

    final fallbackName = _readString(data, const [
      'product_name',
      'productName',
      'item_name',
      'itemName',
      'menu_name',
      'menuName',
    ]);
    if (fallbackName.isNotEmpty) {
      final quantity =
          (_readDouble(data, const ['quantity', 'qty', 'count', 'units']) ?? 1)
              .round();

      final amount =
          _readDouble(data, const [
            'total',
            'total_amount',
            'totalAmount',
            'line_total',
            'lineTotal',
            'amount',
            'price',
          ]) ??
          0;

      return [
        _SoldItem(
          name: fallbackName,
          quantity: quantity <= 0 ? 1 : quantity,
          amount: amount,
        ),
      ];
    }

    return const <_SoldItem>[];
  }

  bool _isPendingIncident(Map<String, dynamic> data) {
    final status = _readString(data, const [
      'status',
      'state',
      'incident_status',
      'incidentStatus',
    ]).toLowerCase();

    if (status.isNotEmpty) {
      if (status.contains('resolved') ||
          status.contains('closed') ||
          status.contains('validated') ||
          status.contains('done')) {
        return false;
      }
      if (status.contains('pending') ||
          status.contains('open') ||
          status.contains('new') ||
          status.contains('todo') ||
          status.contains('valider')) {
        return true;
      }
    }

    final resolved = _readBool(data, const [
      'resolved',
      'is_resolved',
      'isResolved',
      'closed',
      'isClosed',
      'validated',
      'isValidated',
    ]);

    if (resolved != null) {
      return !resolved;
    }

    return true;
  }

  bool _isLowStock(Map<String, dynamic> data) {
    final stock = _readDouble(data, const [
      'stock',
      'stock_quantity',
      'stockQuantity',
      'quantity',
      'qty',
      'remaining',
      'current_stock',
      'currentStock',
    ]);

    if (stock == null) {
      return false;
    }

    final threshold = _readDouble(data, const [
      'min_stock',
      'minStock',
      'alert_threshold',
      'alertThreshold',
      'reorder_level',
      'reorderLevel',
      'minimum',
    ]);

    final limit = threshold ?? 5;
    return stock <= limit;
  }

  List<TopProductData> _buildTopProducts(
    Map<String, _ProductAccumulator> todayProducts,
    Map<String, _ProductAccumulator> yesterdayProducts,
  ) {
    final sorted = todayProducts.values.toList(growable: false)
      ..sort((a, b) {
        final amountCompare = b.revenue.compareTo(a.revenue);
        if (amountCompare != 0) return amountCompare;
        return b.quantity.compareTo(a.quantity);
      });

    return sorted
        .take(3)
        .map((product) {
          final yesterday = yesterdayProducts[product.key]?.revenue ?? 0;
          final growth = yesterday <= 0
              ? (product.revenue > 0 ? 100.0 : 0.0)
              : ((product.revenue - yesterday) / yesterday) * 100.0;

          return TopProductData(
            name: product.name,
            quantity: product.quantity,
            revenue: product.revenue,
            growthPercent: growth,
          );
        })
        .toList(growable: false);
  }

  void _accumulateProducts(
    Map<String, _ProductAccumulator> bucket,
    List<_SoldItem> items,
  ) {
    for (final item in items) {
      final key = _normalizeProductKey(item.name);
      if (key.isEmpty) continue;
      final existing = bucket.putIfAbsent(
        key,
        () => _ProductAccumulator(key: key, name: item.name),
      );
      existing.quantity += item.quantity;
      existing.revenue += item.amount;
    }
  }

  bool _isWithinRange(DateTime value, DateTime start, DateTime endExclusive) {
    return !value.isBefore(start) && value.isBefore(endExclusive);
  }

  String _normalizeProductKey(String value) {
    return value.trim().toLowerCase();
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
      final value = _toDouble(data[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }

  DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final date = _toDateTime(data[key]);
      if (date != null) {
        return date;
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    if (value is String) {
      final normalized = value
          .replaceAll('\u00A0', '')
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      final cleaned = normalized.replaceAll(RegExp(r'[^0-9.\-]'), '');
      if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
      return double.tryParse(cleaned);
    }

    return null;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is int) {
      final isMs = value > 9999999999;
      return DateTime.fromMillisecondsSinceEpoch(
        isMs ? value : value * 1000,
      ).toLocal();
    }
    if (value is double) {
      final asInt = value.round();
      final isMs = asInt > 9999999999;
      return DateTime.fromMillisecondsSinceEpoch(
        isMs ? asInt : asInt * 1000,
      ).toLocal();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }
    if (value is Map) {
      final seconds = _toDouble(value['_seconds'] ?? value['seconds']);
      if (seconds != null) {
        final nanos =
            _toDouble(value['_nanoseconds'] ?? value['nanoseconds']) ?? 0;
        final millis = (seconds * 1000 + nanos / 1000000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
      }
    }
    return null;
  }

  Map<String, dynamic>? _toStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry('$key', item));
    }
    return null;
  }
}

class _FirestoreRecord {
  const _FirestoreRecord({
    required this.id,
    required this.path,
    required this.data,
  });

  final String id;
  final String path;
  final Map<String, dynamic> data;
}

class _OrderEntry {
  const _OrderEntry({
    required this.createdAt,
    required this.amount,
    required this.items,
  });

  final DateTime createdAt;
  final double amount;
  final List<_SoldItem> items;
}

class _SoldItem {
  const _SoldItem({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final int quantity;
  final double amount;
}

class _ProductAccumulator {
  _ProductAccumulator({required this.key, required this.name});

  final String key;
  final String name;
  int quantity = 0;
  double revenue = 0;
}
