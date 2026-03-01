import 'package:flutter/material.dart';

import 'order_model.dart';

enum TableState { free, occupied, reserved, cleaning, unavailable }

enum TableServicePhase {
  none,
  waitingForOrder,
  orderTaken,
  inKitchen,
  readyToServe,
  dining,
  payment,
  paid,
  cleaning,
  freeAgain,
}

enum TableUrgencyLevel { normal, watch, urgent }

enum TablesQuickFilter {
  all,
  free,
  occupied,
  waitingOrder,
  inKitchen,
  paymentPending,
  cleaning,
  alerts,
}

enum TablesViewMode { list, floor }

class TableFirestoreSchema {
  static const String tableState = 'table_state';
  static const String servicePhase = 'service_phase';
  static const String urgencyLevel = 'urgency_level';
  static const String guestCount = 'guest_count';
  static const String activeTicketId = 'active_ticket_id';
  static const String activeTicketTotal = 'active_ticket_total';
  static const String serverName = 'server_name';
  static const String zoneName = 'zone';
  static const String phaseStartedAt = 'phase_started_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> exampleTableDocument({
    required int tableNumber,
    required TableState state,
    required TableServicePhase phase,
    required TableUrgencyLevel urgency,
    int guests = 0,
    double totalAmount = 0,
    String server = '',
    String zone = '',
    String activeTicket = '',
  }) {
    final nowIso = DateTime.now().toIso8601String();
    return <String, dynamic>{
      'table_number': tableNumber,
      tableState: state.name,
      servicePhase: phase.name,
      urgencyLevel: urgency.name,
      guestCount: guests,
      activeTicketId: activeTicket,
      activeTicketTotal: totalAmount,
      serverName: server,
      zoneName: zone,
      phaseStartedAt: nowIso,
      updatedAt: nowIso,
    };
  }
}

class TableOverviewModel {
  const TableOverviewModel({
    required this.tableKey,
    required this.tableId,
    required this.tableNumber,
    required this.tableSort,
    required this.tableState,
    required this.servicePhase,
    required this.urgencyLevel,
    required this.guestCount,
    required this.zoneName,
    required this.serverName,
    required this.phaseStartedAt,
    required this.updatedAt,
    required this.totalAmount,
    required this.orderItems,
    required this.hasActiveOrder,
  });

  final String tableKey;
  final String tableId;
  final String tableNumber;
  final int tableSort;
  final TableState tableState;
  final TableServicePhase servicePhase;
  final TableUrgencyLevel urgencyLevel;
  final int guestCount;
  final String zoneName;
  final String serverName;
  final DateTime? phaseStartedAt;
  final DateTime? updatedAt;
  final double totalAmount;
  final List<OrderItem> orderItems;
  final bool hasActiveOrder;

  bool get hasAlert => urgencyLevel != TableUrgencyLevel.normal;

  bool get isOccupied =>
      tableState == TableState.occupied || tableState == TableState.cleaning;
}

class TablesSummaryCounts {
  const TablesSummaryCounts({
    required this.total,
    required this.free,
    required this.occupied,
    required this.waitingOrder,
    required this.inKitchen,
    required this.paymentPending,
    required this.cleaning,
    required this.alerts,
  });

  final int total;
  final int free;
  final int occupied;
  final int waitingOrder;
  final int inKitchen;
  final int paymentPending;
  final int cleaning;
  final int alerts;
}

TablesSummaryCounts computeTablesSummaryCounts(
  List<TableOverviewModel> tables,
) {
  var free = 0;
  var occupied = 0;
  var waitingOrder = 0;
  var inKitchen = 0;
  var paymentPending = 0;
  var cleaning = 0;
  var alerts = 0;

  for (final table in tables) {
    if (table.tableState == TableState.free) {
      free += 1;
    }
    if (table.tableState == TableState.occupied) {
      occupied += 1;
    }
    if (table.servicePhase == TableServicePhase.waitingForOrder) {
      waitingOrder += 1;
    }
    if (table.servicePhase == TableServicePhase.inKitchen) {
      inKitchen += 1;
    }
    if (table.servicePhase == TableServicePhase.payment) {
      paymentPending += 1;
    }
    if (table.tableState == TableState.cleaning ||
        table.servicePhase == TableServicePhase.cleaning) {
      cleaning += 1;
    }
    if (table.hasAlert) {
      alerts += 1;
    }
  }

  return TablesSummaryCounts(
    total: tables.length,
    free: free,
    occupied: occupied,
    waitingOrder: waitingOrder,
    inKitchen: inKitchen,
    paymentPending: paymentPending,
    cleaning: cleaning,
    alerts: alerts,
  );
}

String tableStateLabel(TableState state) {
  switch (state) {
    case TableState.free:
      return 'Libre';
    case TableState.occupied:
      return 'Occupee';
    case TableState.reserved:
      return 'Reservee';
    case TableState.cleaning:
      return 'Nettoyage';
    case TableState.unavailable:
      return 'Indisponible';
  }
}

String tableServicePhaseLabel(TableServicePhase phase) {
  switch (phase) {
    case TableServicePhase.none:
      return 'Sans phase';
    case TableServicePhase.waitingForOrder:
      return 'Attente commande';
    case TableServicePhase.orderTaken:
      return 'Commande prise';
    case TableServicePhase.inKitchen:
      return 'En cuisine';
    case TableServicePhase.readyToServe:
      return 'Pret a servir';
    case TableServicePhase.dining:
      return 'Service / repas';
    case TableServicePhase.payment:
      return 'Paiement';
    case TableServicePhase.paid:
      return 'Payee';
    case TableServicePhase.cleaning:
      return 'Nettoyage';
    case TableServicePhase.freeAgain:
      return 'Libre a nouveau';
  }
}

IconData tableServicePhaseIcon(TableServicePhase phase) {
  switch (phase) {
    case TableServicePhase.none:
      return Icons.remove_rounded;
    case TableServicePhase.waitingForOrder:
      return Icons.edit_note_rounded;
    case TableServicePhase.orderTaken:
      return Icons.receipt_long_rounded;
    case TableServicePhase.inKitchen:
      return Icons.kitchen_rounded;
    case TableServicePhase.readyToServe:
      return Icons.room_service_rounded;
    case TableServicePhase.dining:
      return Icons.restaurant_rounded;
    case TableServicePhase.payment:
      return Icons.payments_rounded;
    case TableServicePhase.paid:
      return Icons.check_circle_rounded;
    case TableServicePhase.cleaning:
      return Icons.cleaning_services_rounded;
    case TableServicePhase.freeAgain:
      return Icons.table_restaurant_rounded;
  }
}

String tableUrgencyLabel(TableUrgencyLevel urgencyLevel) {
  switch (urgencyLevel) {
    case TableUrgencyLevel.normal:
      return 'Normal';
    case TableUrgencyLevel.watch:
      return 'A surveiller';
    case TableUrgencyLevel.urgent:
      return 'Urgent';
  }
}

String tablesQuickFilterLabel(TablesQuickFilter filter) {
  switch (filter) {
    case TablesQuickFilter.all:
      return 'Toutes';
    case TablesQuickFilter.free:
      return 'Libres';
    case TablesQuickFilter.occupied:
      return 'Occupees';
    case TablesQuickFilter.waitingOrder:
      return 'Attente';
    case TablesQuickFilter.inKitchen:
      return 'Cuisine';
    case TablesQuickFilter.paymentPending:
      return 'Paiement';
    case TablesQuickFilter.cleaning:
      return 'Nettoyage';
    case TablesQuickFilter.alerts:
      return 'Alertes';
  }
}

class TableStateStyle {
  const TableStateStyle({
    required this.baseColor,
    required this.textColor,
    required this.borderColor,
    required this.surfaceColor,
  });

  final Color baseColor;
  final Color textColor;
  final Color borderColor;
  final Color surfaceColor;
}

TableStateStyle tableStateStyle(TableState state) {
  switch (state) {
    case TableState.free:
      return const TableStateStyle(
        baseColor: Color(0xFF16A34A),
        textColor: Color(0xFF166534),
        borderColor: Color(0xFFBBF7D0),
        surfaceColor: Color(0xFFF0FDF4),
      );
    case TableState.occupied:
      return const TableStateStyle(
        baseColor: Color(0xFF2563EB),
        textColor: Color(0xFF1D4ED8),
        borderColor: Color(0xFFBFDBFE),
        surfaceColor: Color(0xFFEFF6FF),
      );
    case TableState.reserved:
      return const TableStateStyle(
        baseColor: Color(0xFF9333EA),
        textColor: Color(0xFF7E22CE),
        borderColor: Color(0xFFE9D5FF),
        surfaceColor: Color(0xFFFAF5FF),
      );
    case TableState.cleaning:
      return const TableStateStyle(
        baseColor: Color(0xFF64748B),
        textColor: Color(0xFF334155),
        borderColor: Color(0xFFE2E8F0),
        surfaceColor: Color(0xFFF8FAFC),
      );
    case TableState.unavailable:
      return const TableStateStyle(
        baseColor: Color(0xFF475569),
        textColor: Color(0xFF1E293B),
        borderColor: Color(0xFFCBD5E1),
        surfaceColor: Color(0xFFF1F5F9),
      );
  }
}

class TablePhaseStyle {
  const TablePhaseStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}

TablePhaseStyle tablePhaseStyle(TableServicePhase phase) {
  switch (phase) {
    case TableServicePhase.none:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFF3F4F6),
        borderColor: Color(0xFFE5E7EB),
        textColor: Color(0xFF6B7280),
      );
    case TableServicePhase.waitingForOrder:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFEEF2FF),
        borderColor: Color(0xFFC7D2FE),
        textColor: Color(0xFF4338CA),
      );
    case TableServicePhase.orderTaken:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFE0F2FE),
        borderColor: Color(0xFFBAE6FD),
        textColor: Color(0xFF0369A1),
      );
    case TableServicePhase.inKitchen:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFFFEDD5),
        borderColor: Color(0xFFFED7AA),
        textColor: Color(0xFF9A3412),
      );
    case TableServicePhase.readyToServe:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
        textColor: Color(0xFFC2410C),
      );
    case TableServicePhase.dining:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFECFEFF),
        borderColor: Color(0xFFB4F5FC),
        textColor: Color(0xFF0E7490),
      );
    case TableServicePhase.payment:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFFEF9C3),
        borderColor: Color(0xFFFDE68A),
        textColor: Color(0xFFA16207),
      );
    case TableServicePhase.paid:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFDCFCE7),
        borderColor: Color(0xFFBBF7D0),
        textColor: Color(0xFF166534),
      );
    case TableServicePhase.cleaning:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFF1F5F9),
        borderColor: Color(0xFFCBD5E1),
        textColor: Color(0xFF334155),
      );
    case TableServicePhase.freeAgain:
      return const TablePhaseStyle(
        backgroundColor: Color(0xFFECFDF5),
        borderColor: Color(0xFFA7F3D0),
        textColor: Color(0xFF065F46),
      );
  }
}

class TableUrgencyStyle {
  const TableUrgencyStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}

TableUrgencyStyle tableUrgencyStyle(TableUrgencyLevel urgencyLevel) {
  switch (urgencyLevel) {
    case TableUrgencyLevel.normal:
      return const TableUrgencyStyle(
        backgroundColor: Color(0xFFEEF2FF),
        borderColor: Color(0xFFC7D2FE),
        textColor: Color(0xFF4338CA),
      );
    case TableUrgencyLevel.watch:
      return const TableUrgencyStyle(
        backgroundColor: Color(0xFFFFEDD5),
        borderColor: Color(0xFFFED7AA),
        textColor: Color(0xFF9A3412),
      );
    case TableUrgencyLevel.urgent:
      return const TableUrgencyStyle(
        backgroundColor: Color(0xFFFEE2E2),
        borderColor: Color(0xFFFECACA),
        textColor: Color(0xFFB91C1C),
      );
  }
}

List<TableOverviewModel> buildExampleTableOverviewData() {
  final now = DateTime.now();
  return [
    TableOverviewModel(
      tableKey: '1',
      tableId: 'table_001',
      tableNumber: '1',
      tableSort: 1,
      tableState: TableState.occupied,
      servicePhase: TableServicePhase.waitingForOrder,
      urgencyLevel: TableUrgencyLevel.watch,
      guestCount: 2,
      zoneName: 'Terrasse',
      serverName: 'Reda',
      phaseStartedAt: now.subtract(const Duration(minutes: 8)),
      updatedAt: now.subtract(const Duration(minutes: 2)),
      totalAmount: 0,
      orderItems: const [],
      hasActiveOrder: false,
    ),
    TableOverviewModel(
      tableKey: '2',
      tableId: 'table_002',
      tableNumber: '2',
      tableSort: 2,
      tableState: TableState.occupied,
      servicePhase: TableServicePhase.inKitchen,
      urgencyLevel: TableUrgencyLevel.normal,
      guestCount: 4,
      zoneName: 'Salle A',
      serverName: 'Fatou',
      phaseStartedAt: now.subtract(const Duration(minutes: 12)),
      updatedAt: now.subtract(const Duration(minutes: 1)),
      totalAmount: 3100,
      orderItems: [
        OrderItem(name: 'Croissant', quantity: 3),
        OrderItem(name: 'Cafe', quantity: 2),
      ],
      hasActiveOrder: true,
    ),
    TableOverviewModel(
      tableKey: '3',
      tableId: 'table_003',
      tableNumber: '3',
      tableSort: 3,
      tableState: TableState.occupied,
      servicePhase: TableServicePhase.payment,
      urgencyLevel: TableUrgencyLevel.urgent,
      guestCount: 3,
      zoneName: 'Salle A',
      serverName: 'Reda',
      phaseStartedAt: now.subtract(const Duration(minutes: 14)),
      updatedAt: now.subtract(const Duration(minutes: 4)),
      totalAmount: 8600,
      orderItems: [
        OrderItem(name: 'Burger', quantity: 2),
        OrderItem(name: 'Jus mangue', quantity: 3),
      ],
      hasActiveOrder: true,
    ),
    TableOverviewModel(
      tableKey: '4',
      tableId: 'table_004',
      tableNumber: '4',
      tableSort: 4,
      tableState: TableState.free,
      servicePhase: TableServicePhase.none,
      urgencyLevel: TableUrgencyLevel.normal,
      guestCount: 0,
      zoneName: 'Salle B',
      serverName: '',
      phaseStartedAt: null,
      updatedAt: now.subtract(const Duration(minutes: 5)),
      totalAmount: 0,
      orderItems: const [],
      hasActiveOrder: false,
    ),
    TableOverviewModel(
      tableKey: '5',
      tableId: 'table_005',
      tableNumber: '5',
      tableSort: 5,
      tableState: TableState.reserved,
      servicePhase: TableServicePhase.none,
      urgencyLevel: TableUrgencyLevel.normal,
      guestCount: 0,
      zoneName: 'VIP',
      serverName: '',
      phaseStartedAt: null,
      updatedAt: now.subtract(const Duration(minutes: 3)),
      totalAmount: 0,
      orderItems: const [],
      hasActiveOrder: false,
    ),
    TableOverviewModel(
      tableKey: '6',
      tableId: 'table_006',
      tableNumber: '6',
      tableSort: 6,
      tableState: TableState.cleaning,
      servicePhase: TableServicePhase.cleaning,
      urgencyLevel: TableUrgencyLevel.watch,
      guestCount: 0,
      zoneName: 'Terrasse',
      serverName: 'Mariama',
      phaseStartedAt: now.subtract(const Duration(minutes: 9)),
      updatedAt: now.subtract(const Duration(minutes: 2)),
      totalAmount: 0,
      orderItems: const [],
      hasActiveOrder: false,
    ),
  ];
}
