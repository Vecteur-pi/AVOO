import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentStatus { pending, validated, ignored }

enum IncidentCategory { food, drink, other }

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.incidentNumber,
    required this.tableLabel,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String incidentNumber;
  final String tableLabel;
  final String title;
  final String description;
  final double totalAmount;
  final IncidentCategory category;
  final IncidentStatus status;
  final DateTime createdAt;

  /// Minutes elapsed since the incident was created.
  int get minutesElapsed =>
      DateTime.now().difference(createdAt).inMinutes.clamp(0, 9999);

  factory IncidentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Status
    final rawStatus = _str(data, const ['status', 'state', 'incident_status']).toLowerCase();
    IncidentStatus status;
    if (rawStatus.contains('valid') || rawStatus.contains('done') || rawStatus.contains('closed')) {
      status = IncidentStatus.validated;
    } else if (rawStatus.contains('ignor') || rawStatus.contains('dismiss')) {
      status = IncidentStatus.ignored;
    } else {
      status = IncidentStatus.pending;
    }

    // Category / icon
    final rawCategory = _str(data, const ['category', 'type', 'kind']).toLowerCase();
    IncidentCategory category;
    if (rawCategory.contains('drink') || rawCategory.contains('verre') || rawCategory.contains('boisson')) {
      category = IncidentCategory.drink;
    } else if (rawCategory.contains('food') || rawCategory.contains('plat') || rawCategory.contains('repas')) {
      category = IncidentCategory.food;
    } else {
      category = IncidentCategory.other;
    }

    // Table label
    final tableNum = _str(data, const ['table', 'table_number', 'tableNumber', 'table_label', 'tableLabel']);
    final tableLabel = tableNum.startsWith('TABLE') ? tableNum : (tableNum.isEmpty ? 'TABLE ?' : 'TABLE $tableNum');

    // Incident number
    final num = _str(data, const ['incident_number', 'incidentNumber', 'number', 'ref']);
    final incidentNumber = num.isEmpty
        ? '#INCIDENT-${doc.id.substring(0, 4).toUpperCase()}'
        : (num.startsWith('#') ? num : '#$num');

    // Amount
    final amount = _dbl(data, const ['total', 'amount', 'total_amount', 'totalAmount', 'cost']);

    // Date
    final createdAt = _date(data, const ['created_at', 'createdAt', 'timestamp', 'date']) ?? DateTime.now();

    return IncidentModel(
      id: doc.id,
      incidentNumber: incidentNumber,
      tableLabel: tableLabel,
      title: _str(data, const ['title', 'name', 'subject', 'incident_title']),
      description: _str(data, const ['description', 'detail', 'message', 'notes', 'note']),
      totalAmount: amount ?? 0,
      category: category,
      status: status,
      createdAt: createdAt,
    );
  }

  // ---- Helpers ----

  static String _str(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static double? _dbl(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final clean = v.replaceAll(RegExp(r'[^0-9.\-]'), '');
        final parsed = double.tryParse(clean);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is Timestamp) return v.toDate().toLocal();
      if (v is DateTime) return v.toLocal();
      if (v is String) {
        final p = DateTime.tryParse(v);
        if (p != null) return p.toLocal();
      }
    }
    return null;
  }
}
