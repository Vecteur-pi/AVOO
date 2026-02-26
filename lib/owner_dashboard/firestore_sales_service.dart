import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesPoint {
  const SalesPoint({
    required this.hourLabel,
    required this.hourKey,
    required this.value,
  });

  final String hourLabel;
  final String hourKey;
  final int value;
}

class SalesByHourSnapshot {
  const SalesByHourSnapshot({
    required this.documentId,
    required this.points,
    required this.hasFirestoreHours,
  });

  final String documentId;
  final List<SalesPoint> points;
  final bool hasFirestoreHours;

  int get peakIndex {
    if (points.isEmpty) {
      return 0;
    }
    var peak = 0;
    for (var index = 1; index < points.length; index++) {
      if (points[index].value > points[peak].value) {
        peak = index;
      }
    }
    return peak;
  }

  int get peakValue {
    var maxValue = 0;
    for (final point in points) {
      if (point.value > maxValue) {
        maxValue = point.value;
      }
    }
    return maxValue;
  }

  double get averageValue {
    if (points.isEmpty) {
      return 0;
    }
    var total = 0;
    for (final point in points) {
      total += point.value;
    }
    return total / points.length;
  }
}

class FirestoreSalesService {
  FirestoreSalesService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int startHour = 8;
  static const int endHour = 17;

  final FirebaseFirestore _firestore;

  Stream<SalesByHourSnapshot> watchTodaySales({
    DateTime Function()? nowProvider,
  }) {
    final now = (nowProvider ?? DateTime.now)();
    return watchSalesForDate(now);
  }

  Stream<SalesByHourSnapshot> watchSalesForDate(DateTime date) {
    final documentId = documentIdForDate(date);
    return _firestore.collection('salesHourly').doc(documentId).snapshots().map(
      (snapshot) {
        final data = snapshot.data();
        final hoursMap = _extractHoursMap(data);
        final hasHoursField = snapshot.exists && hoursMap != null;

        return SalesByHourSnapshot(
          documentId: documentId,
          points: _buildPoints(hoursMap),
          hasFirestoreHours: hasHoursField,
        );
      },
    );
  }

  static String documentIdForDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, dynamic>? _extractHoursMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return null;
    }

    for (final key in const ['hours', 'hourly', 'salesByHour', 'byHour']) {
      final candidate = data[key];
      if (candidate is! Map) {
        continue;
      }
      final normalized = _normalizeHourKeys(_stringifyMap(candidate));
      if (normalized != null) {
        return normalized;
      }
    }

    return _normalizeHourKeys(data);
  }

  Map<String, dynamic>? _normalizeHourKeys(Map<String, dynamic> source) {
    final normalized = <String, dynamic>{};
    source.forEach((rawKey, rawValue) {
      final hour = _parseHourKey(rawKey);
      if (hour == null) {
        return;
      }
      final key = hour.toString().padLeft(2, '0');
      normalized[key] = rawValue;
    });
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int? _parseHourKey(String rawKey) {
    final value = rawKey.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2})h?$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final hour = int.tryParse(match.group(1)!);
    if (hour == null || hour < 0 || hour > 23) {
      return null;
    }
    return hour;
  }

  List<SalesPoint> _buildPoints(Map<String, dynamic>? hoursMap) {
    final points = <SalesPoint>[];
    for (var hour = startHour; hour <= endHour; hour++) {
      final key = hour.toString().padLeft(2, '0');
      points.add(
        SalesPoint(
          hourLabel: '${hour}h',
          hourKey: key,
          value: _parsePositiveInt(hoursMap?[key]),
        ),
      );
    }
    return points;
  }

  Map<String, dynamic> _stringifyMap(Map<dynamic, dynamic> raw) {
    final casted = <String, dynamic>{};
    raw.forEach((dynamic key, dynamic value) {
      casted[key.toString()] = value;
    });
    return casted;
  }

  int _parsePositiveInt(dynamic value) {
    if (value is int) {
      return math.max(0, value);
    }
    if (value is double) {
      return math.max(0, value.round());
    }
    if (value is num) {
      return math.max(0, value.toInt());
    }
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9-]'), '');
      if (normalized.isEmpty) {
        return 0;
      }
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return math.max(0, parsed);
      }
    }
    return 0;
  }
}
