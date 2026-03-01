import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../models/table_dashboard_models.dart';
import '../repository/order_repository.dart';
import 'widgets/table_card.dart';
import 'widgets/table_details_sheet.dart';
import 'widgets/tables_summary.dart';
import 'widgets/zone_plan_container.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderRepository _repository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();

  TablesQuickFilter _selectedFilter = TablesQuickFilter.all;
  String? _selectedZoneFilter;
  TablesViewMode _viewMode = TablesViewMode.list;
  Timer? _ticker;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _tablesStream {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('tables')
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F6F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildSearchAndControls(),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _repository.getOrdersStream(widget.restaurantId),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.hasError) {
                  return _buildErrorState(orderSnapshot.error.toString());
                }

                final orders = orderSnapshot.data ?? const <OrderModel>[];

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _tablesStream,
                  builder: (context, tableSnapshot) {
                    if (tableSnapshot.hasError) {
                      if (_isPermissionDenied(tableSnapshot.error)) {
                        final overview = _buildOverview(
                          tables:
                              const <
                                QueryDocumentSnapshot<Map<String, dynamic>>
                              >[],
                          orders: orders,
                        );
                        final filtered = _applyFilters(overview);
                        return _buildOverviewBody(
                          allTables: overview,
                          filteredTables: filtered,
                          permissionFallbackMode: true,
                        );
                      }
                      return _buildErrorState(tableSnapshot.error.toString());
                    }

                    if (orderSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !orderSnapshot.hasData &&
                        (tableSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            !tableSnapshot.hasData)) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF739760),
                        ),
                      );
                    }

                    final tableDocs =
                        tableSnapshot.data?.docs ??
                        const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                    final overview = _buildOverview(
                      tables: tableDocs,
                      orders: orders,
                    );
                    final filtered = _applyFilters(overview);
                    return _buildOverviewBody(
                      allTables: overview,
                      filteredTables: filtered,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          const Text(
            'Tables',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontFamily: 'Serif',
              letterSpacing: -0.5,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          _ViewModeToggle(
            selectedMode: _viewMode,
            onModeChanged: (mode) {
              setState(() {
                _viewMode = mode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher table, zone, serveur...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showFilterMenu,
              child: Container(
                width: 56,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF4B5563)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TableOverviewModel> _buildOverview({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tables,
    required List<OrderModel> orders,
  }) {
    final validOrders = orders
        .where((order) => order.status != OrderStatus.ingore)
        .toList(growable: false);

    final latestOrderByTable = <String, OrderModel>{};
    for (final order in validOrders) {
      final key = _normalizeTableKey(order.tableNumber);
      if (key.isEmpty) {
        continue;
      }
      final current = latestOrderByTable[key];
      if (current == null ||
          order.updatedAt.isAfter(current.updatedAt) ||
          (order.updatedAt.isAtSameMomentAs(current.updatedAt) &&
              order.createdAt.isAfter(current.createdAt))) {
        latestOrderByTable[key] = order;
      }
    }

    final parsedTables = <TableOverviewModel>[];
    final seenKeys = <String>{};

    for (final doc in tables) {
      final data = doc.data();
      final key = _tableKeyFromDoc(data, fallbackId: doc.id);
      if (key.isEmpty) {
        continue;
      }

      final matchingOrder = latestOrderByTable[key];
      final tableState = _resolveTableState(data, matchingOrder);
      final orderForUi =
          tableState == TableState.occupied || tableState == TableState.cleaning
          ? matchingOrder
          : null;
      final servicePhase = _resolveServicePhase(data, orderForUi, tableState);
      final phaseStartedAt = _resolvePhaseStartedAt(
        tableState: tableState,
        servicePhase: servicePhase,
        tableData: data,
        order: orderForUi,
      );
      final updatedAt = _resolveUpdatedAt(data, orderForUi);
      final urgency = _resolveUrgency(
        tableData: data,
        tableState: tableState,
        servicePhase: servicePhase,
        phaseStartedAt: phaseStartedAt,
      );
      final tableNumber = _readInt(data, const [
        'table_number',
        'tableNumber',
        'number',
      ]);
      final displayNumber =
          tableNumber?.toString() ??
          _extractNumberFromText(
            _readString(data, const [
              'label',
              'name',
              'table',
              'table_id',
              'tableId',
            ]),
          ) ??
          doc.id;

      parsedTables.add(
        TableOverviewModel(
          tableKey: key,
          tableId: doc.id,
          tableNumber: displayNumber,
          tableSort: tableNumber ?? _sortFromDisplay(displayNumber),
          tableState: tableState,
          servicePhase: servicePhase,
          urgencyLevel: urgency,
          guestCount:
              _readInt(data, const [
                'guest_count',
                'guestCount',
                'covers',
                'people_count',
                'peopleCount',
                'seats_occupied',
                'seatsOccupied',
              ]) ??
              0,
          zoneName: _readString(data, const [
            'zone',
            'area',
            'area_name',
            'areaName',
            'section',
          ]),
          serverName: _readString(data, const [
            'server_name',
            'serverName',
            'waiter_name',
            'waiterName',
            'assigned_to_name',
            'assignedToName',
            'assigned_to',
            'assignedTo',
          ]),
          phaseStartedAt: phaseStartedAt,
          updatedAt: updatedAt,
          totalAmount: _resolveAmount(data, orderForUi, tableState),
          orderItems: orderForUi?.items ?? const <OrderItem>[],
          hasActiveOrder: orderForUi != null,
        ),
      );
      seenKeys.add(key);
    }

    for (final entry in latestOrderByTable.entries) {
      if (seenKeys.contains(entry.key)) {
        continue;
      }
      final order = entry.value;
      final tableState = _stateFromOrderStatus(order.status);
      final servicePhase = _phaseFromOrderStatus(order.status);
      final phaseStartedAt = order.updatedAt.isAfter(order.createdAt)
          ? order.updatedAt
          : order.createdAt;
      final displayNumber = order.tableNumber.isEmpty
          ? entry.key
          : order.tableNumber;

      parsedTables.add(
        TableOverviewModel(
          tableKey: entry.key,
          tableId: 'order_only_${entry.key}',
          tableNumber: displayNumber,
          tableSort: _sortFromDisplay(displayNumber),
          tableState: tableState,
          servicePhase: servicePhase,
          urgencyLevel: _deriveUrgency(
            tableState: tableState,
            servicePhase: servicePhase,
            phaseStartedAt: phaseStartedAt,
          ),
          guestCount: 0,
          zoneName: '',
          serverName: '',
          phaseStartedAt: phaseStartedAt,
          updatedAt: order.updatedAt,
          totalAmount: order.totalAmount,
          orderItems: order.items,
          hasActiveOrder: true,
        ),
      );
    }

    parsedTables.sort((a, b) {
      final tableCompare = a.tableSort.compareTo(b.tableSort);
      if (tableCompare != 0) {
        return tableCompare;
      }
      return a.tableNumber.compareTo(b.tableNumber);
    });

    return parsedTables;
  }

  List<TableOverviewModel> _applyFilters(List<TableOverviewModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items
        .where((item) {
          // Status filter
          if (!_matchesQuickFilter(item, _selectedFilter)) {
            return false;
          }

          // Zone filter
          if (_selectedZoneFilter != null && _selectedZoneFilter != 'all') {
            final normalizedZone = item.zoneName.trim().toLowerCase();
            if (normalizedZone != _selectedZoneFilter) {
              return false;
            }
          }

          // Text Search
          if (query.isEmpty) {
            return true;
          }

          final haystack = <String>[
            item.tableNumber.toLowerCase(),
            item.zoneName.toLowerCase(),
            item.serverName.toLowerCase(),
            tableStateLabel(item.tableState).toLowerCase(),
            tableServicePhaseLabel(item.servicePhase).toLowerCase(),
            tableUrgencyLabel(item.urgencyLevel).toLowerCase(),
          ];

          return haystack.any((value) => value.contains(query));
        })
        .toList(growable: false);
  }

  bool _matchesQuickFilter(TableOverviewModel item, TablesQuickFilter filter) {
    switch (filter) {
      case TablesQuickFilter.all:
        return true;
      case TablesQuickFilter.free:
        return item.tableState == TableState.free;
      case TablesQuickFilter.occupied:
        return item.tableState == TableState.occupied;
      case TablesQuickFilter.waitingOrder:
        return item.servicePhase == TableServicePhase.waitingForOrder;
      case TablesQuickFilter.inKitchen:
        return item.servicePhase == TableServicePhase.inKitchen;
      case TablesQuickFilter.paymentPending:
        return item.servicePhase == TableServicePhase.payment;
      case TablesQuickFilter.cleaning:
        return item.tableState == TableState.cleaning ||
            item.servicePhase == TableServicePhase.cleaning;
      case TablesQuickFilter.alerts:
        return item.hasAlert;
    }
  }

  Widget _buildOverviewBody({
    required List<TableOverviewModel> allTables,
    required List<TableOverviewModel> filteredTables,
    bool permissionFallbackMode = false,
  }) {
    if (allTables.isEmpty) {
      return _buildEmptyState(
        message:
            'Aucune table configuree. Ajoutez vos tables depuis la configuration du restaurant.',
      );
    }

    // Extract unique zones
    final zoneNames = allTables
        .map((t) => t.zoneName.trim())
        .where((z) => z.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    // Map counts per zone (considering only the status filter)
    final tablesWithCurrentStatus = allTables.where((item) => _matchesQuickFilter(item, _selectedFilter)).toList();

    final chipsData = <SummaryChipData>[
      SummaryChipData(
        id: 'all',
        label: 'Toutes',
        count: tablesWithCurrentStatus.length,
      ),
      for (final zone in zoneNames)
        SummaryChipData(
          id: zone.toLowerCase(),
          label: zone,
          count: tablesWithCurrentStatus
              .where((t) => t.zoneName.trim().toLowerCase() == zone.toLowerCase())
              .length,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (permissionFallbackMode) _buildPermissionBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: TablesSummary(
            chipsData: chipsData,
            selectedZone: _selectedZoneFilter ?? 'all',
            onZoneSelected: (zoneId) {
              setState(() {
                _selectedZoneFilter = zoneId;
              });
            },
          ),
        ),
        Expanded(
          child: _viewMode == TablesViewMode.floor
              ? _buildFloorView(filteredTables)
              : _buildCompactGrid(filteredTables),
        ),
      ],
    );
  }

  Widget _buildPermissionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFACD9A)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFB45309),
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Acces aux tables refuse. Apercu base sur les commandes disponibles.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGrid(List<TableOverviewModel> filteredTables) {
    if (filteredTables.isEmpty) {
      return _buildEmptyState(
        message: 'Aucune table ne correspond aux filtres actuels.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        var crossAxisCount = (maxWidth / 200).floor();
        crossAxisCount = crossAxisCount.clamp(1, 4);
        final singleColumn = crossAxisCount == 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: singleColumn ? 2.1 : 1.07,
          ),
          itemCount: filteredTables.length,
          itemBuilder: (context, index) {
            final table = filteredTables[index];
            return TableCard(
              table: table,
              elapsedLabel: _elapsedLabel(table.phaseStartedAt),
              amountLabel: _formatAmount(table.totalAmount),
              onTap: () => _openTableDetails(table),
            );
          },
        );
      },
    );
  }

  Widget _buildFloorView(List<TableOverviewModel> filteredTables) {
    if (filteredTables.isEmpty) {
      return _buildEmptyState(
        message: 'Aucune table ne correspond aux filtres.',
      );
    }

    // Group tables by zoneName
    final groupedTables = <String, List<TableOverviewModel>>{};
    for (final table in filteredTables) {
      final zone = table.zoneName.trim();
      groupedTables.putIfAbsent(zone, () => []).add(table);
    }

    // Sort zones (empty zone last, otherwise alphabetical)
    final sortedZones = groupedTables.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty && b.isNotEmpty) return 1;
        if (a.isNotEmpty && b.isEmpty) return -1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: sortedZones.length,
      itemBuilder: (context, index) {
        final zone = sortedZones[index];
        final tablesInZone = groupedTables[zone]!;

        return ZonePlanContainer(
          zoneName: zone,
          tables: tablesInZone,
          onTableTap: _openTableDetails,
        );
      },
    );
  }

  void _openTableDetails(TableOverviewModel table) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: TableDetailsSheet(
            table: table,
            elapsedLabel: _elapsedLabel(table.phaseStartedAt),
            amountLabel: _formatAmount(table.totalAmount),
            canUpdateStatus: !table.tableId.startsWith('order_only_'),
            onStatusUpdate: (tableState, servicePhase) {
              return _updateTableStatus(
                table: table,
                tableState: tableState,
                servicePhase: servicePhase,
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _updateTableStatus({
    required TableOverviewModel table,
    required TableState tableState,
    required TableServicePhase servicePhase,
  }) async {
    if (table.tableId.startsWith('order_only_')) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cette table vient des commandes uniquement. Creez la table dans la configuration pour modifier son etat.',
          ),
        ),
      );
      return false;
    }

    try {
      await _repository.updateTableStatus(
        restaurantId: widget.restaurantId,
        tableId: table.tableId,
        tableState: tableState,
        servicePhase: servicePhase,
      );

      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${table.tableNumber}: ${tableStateLabel(tableState)} '
            '(${tableServicePhaseLabel(servicePhase)}).',
          ),
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mise a jour impossible: $error'),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
      return false;
    }
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_restaurant_rounded,
                color: Color(0xFF9CA3AF),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB91C1C),
                size: 30,
              ),
              const SizedBox(height: 10),
              const Text(
                'Impossible de charger les tables en temps reel.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7F1D1D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPermissionDenied(Object? error) {
    if (error == null) {
      return false;
    }
    if (error is FirebaseException) {
      return error.code == 'permission-denied';
    }
    return error.toString().toLowerCase().contains('permission-denied');
  }

  Future<void> _showFilterMenu() async {
    final selected = await showModalBottomSheet<TablesQuickFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Filtrer les tables',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: TablesQuickFilter.values
                        .map((filter) {
                          final isSelected = filter == _selectedFilter;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: (_) =>
                                Navigator.of(context).pop(filter),
                            label: Text(tablesQuickFilterLabel(filter)),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF1F2937),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFE5E7EB),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedFilter = selected;
    });
  }

  TableState _resolveTableState(
    Map<String, dynamic> tableData,
    OrderModel? order,
  ) {
    final raw = _readString(tableData, const [
      'table_state',
      'tableState',
      'availability_status',
      'availabilityStatus',
      'status',
      'state',
    ]).toLowerCase();

    final explicit = _tableStateFromRaw(raw);
    if (explicit != null) {
      return explicit;
    }

    final phaseFromStatus = _servicePhaseFromRaw(raw);
    if (phaseFromStatus != null) {
      if (phaseFromStatus == TableServicePhase.cleaning ||
          phaseFromStatus == TableServicePhase.freeAgain) {
        return TableState.cleaning;
      }
      return TableState.occupied;
    }

    final isReserved =
        _readBool(tableData, const ['is_reserved', 'isReserved']) ?? false;
    if (isReserved) {
      return TableState.reserved;
    }

    final isUnavailable =
        _readBool(tableData, const [
          'is_unavailable',
          'isUnavailable',
          'out_of_service',
          'outOfService',
        ]) ??
        false;
    if (isUnavailable) {
      return TableState.unavailable;
    }

    final isCleaning =
        _readBool(tableData, const ['is_cleaning', 'isCleaning']) ?? false;
    if (isCleaning) {
      return TableState.cleaning;
    }

    final activeTicketId = _readString(tableData, const [
      'active_ticket_id',
      'activeTicketId',
      'ticket_id',
      'ticketId',
    ]);

    if (order != null) {
      return _stateFromOrderStatus(order.status);
    }

    if (activeTicketId.isNotEmpty) {
      return TableState.occupied;
    }

    return TableState.free;
  }

  TableServicePhase _resolveServicePhase(
    Map<String, dynamic> tableData,
    OrderModel? order,
    TableState tableState,
  ) {
    if (tableState == TableState.free ||
        tableState == TableState.reserved ||
        tableState == TableState.unavailable) {
      return TableServicePhase.none;
    }

    final raw = _readString(tableData, const [
      'service_phase',
      'servicePhase',
      'workflow_phase',
      'workflowPhase',
      'active_ticket_status',
      'activeTicketStatus',
      'order_status',
      'orderStatus',
      'phase',
    ]).toLowerCase();

    final explicit = _servicePhaseFromRaw(raw);
    if (explicit != null) {
      return explicit;
    }

    if (tableState == TableState.cleaning) {
      return TableServicePhase.cleaning;
    }

    if (order != null) {
      return _phaseFromOrderStatus(order.status);
    }

    if (tableState == TableState.occupied) {
      return TableServicePhase.waitingForOrder;
    }

    return TableServicePhase.none;
  }

  TableUrgencyLevel _resolveUrgency({
    required Map<String, dynamic> tableData,
    required TableState tableState,
    required TableServicePhase servicePhase,
    required DateTime? phaseStartedAt,
  }) {
    final raw = _readString(tableData, const [
      'urgency',
      'urgency_level',
      'urgencyLevel',
      'alert_level',
      'alertLevel',
      'attention_level',
      'attentionLevel',
      'attention',
      'alert',
    ]).toLowerCase();

    final explicit = _urgencyFromRaw(raw);
    if (explicit != null) {
      return explicit;
    }

    return _deriveUrgency(
      tableState: tableState,
      servicePhase: servicePhase,
      phaseStartedAt: phaseStartedAt,
    );
  }

  TableUrgencyLevel _deriveUrgency({
    required TableState tableState,
    required TableServicePhase servicePhase,
    required DateTime? phaseStartedAt,
  }) {
    if (tableState == TableState.free ||
        tableState == TableState.reserved ||
        tableState == TableState.unavailable) {
      return TableUrgencyLevel.normal;
    }

    if (phaseStartedAt == null) {
      return TableUrgencyLevel.normal;
    }

    final now = DateTime.now();
    if (phaseStartedAt.isAfter(now)) {
      return TableUrgencyLevel.normal;
    }

    final minutes = now.difference(phaseStartedAt).inMinutes;

    TableUrgencyLevel fromThresholds({
      required int watchAt,
      required int urgentAt,
    }) {
      if (minutes >= urgentAt) {
        return TableUrgencyLevel.urgent;
      }
      if (minutes >= watchAt) {
        return TableUrgencyLevel.watch;
      }
      return TableUrgencyLevel.normal;
    }

    switch (servicePhase) {
      case TableServicePhase.waitingForOrder:
        return fromThresholds(watchAt: 7, urgentAt: 12);
      case TableServicePhase.orderTaken:
        return fromThresholds(watchAt: 15, urgentAt: 25);
      case TableServicePhase.inKitchen:
        return fromThresholds(watchAt: 20, urgentAt: 35);
      case TableServicePhase.readyToServe:
        return fromThresholds(watchAt: 4, urgentAt: 8);
      case TableServicePhase.dining:
        return fromThresholds(watchAt: 75, urgentAt: 110);
      case TableServicePhase.payment:
        return fromThresholds(watchAt: 6, urgentAt: 12);
      case TableServicePhase.paid:
        return fromThresholds(watchAt: 8, urgentAt: 16);
      case TableServicePhase.cleaning:
      case TableServicePhase.freeAgain:
        return fromThresholds(watchAt: 8, urgentAt: 15);
      case TableServicePhase.none:
        if (tableState == TableState.cleaning) {
          return fromThresholds(watchAt: 8, urgentAt: 15);
        }
        if (tableState == TableState.occupied) {
          return fromThresholds(watchAt: 10, urgentAt: 16);
        }
        return TableUrgencyLevel.normal;
    }
  }

  DateTime? _resolvePhaseStartedAt({
    required TableState tableState,
    required TableServicePhase servicePhase,
    required Map<String, dynamic> tableData,
    required OrderModel? order,
  }) {
    final genericPhaseStart = _readDate(tableData, const [
      'phase_started_at',
      'phaseStartedAt',
    ]);

    switch (servicePhase) {
      case TableServicePhase.waitingForOrder:
        return _readDate(tableData, const [
              'seated_at',
              'seatedAt',
              'occupied_at',
              'occupiedAt',
              'opened_at',
              'openedAt',
            ]) ??
            genericPhaseStart ??
            order?.createdAt;
      case TableServicePhase.orderTaken:
        return _readDate(tableData, const [
              'order_taken_at',
              'orderTakenAt',
              'order_started_at',
              'orderStartedAt',
              'opened_at',
              'openedAt',
            ]) ??
            genericPhaseStart ??
            order?.createdAt;
      case TableServicePhase.inKitchen:
        return _readDate(tableData, const [
              'preparation_started_at',
              'preparationStartedAt',
              'kitchen_started_at',
              'kitchenStartedAt',
            ]) ??
            genericPhaseStart ??
            order?.updatedAt ??
            order?.createdAt;
      case TableServicePhase.readyToServe:
        return _readDate(tableData, const ['ready_at', 'readyAt']) ??
            genericPhaseStart ??
            order?.updatedAt ??
            order?.createdAt;
      case TableServicePhase.dining:
        return _readDate(tableData, const [
              'served_at',
              'servedAt',
              'service_at',
              'serviceAt',
            ]) ??
            genericPhaseStart ??
            order?.updatedAt ??
            order?.createdAt;
      case TableServicePhase.payment:
        return _readDate(tableData, const [
              'payment_requested_at',
              'paymentRequestedAt',
              'payment_started_at',
              'paymentStartedAt',
            ]) ??
            genericPhaseStart ??
            order?.updatedAt ??
            order?.createdAt;
      case TableServicePhase.paid:
        return _readDate(tableData, const [
              'paid_at',
              'paidAt',
              'settled_at',
              'settledAt',
            ]) ??
            genericPhaseStart ??
            order?.updatedAt ??
            order?.createdAt;
      case TableServicePhase.cleaning:
        return _readDate(tableData, const [
              'cleaning_started_at',
              'cleaningStartedAt',
              'closed_at',
              'closedAt',
            ]) ??
            genericPhaseStart ??
            order?.updatedAt;
      case TableServicePhase.freeAgain:
        return _readDate(tableData, const [
              'released_at',
              'releasedAt',
              'closed_at',
              'closedAt',
            ]) ??
            genericPhaseStart ??
            _readDate(tableData, const ['updated_at', 'updatedAt']) ??
            order?.updatedAt;
      case TableServicePhase.none:
        if (tableState == TableState.occupied) {
          return _readDate(tableData, const [
                'occupied_at',
                'occupiedAt',
                'opened_at',
                'openedAt',
              ]) ??
              genericPhaseStart ??
              order?.createdAt;
        }
        if (tableState == TableState.cleaning) {
          return _readDate(tableData, const [
                'cleaning_started_at',
                'cleaningStartedAt',
              ]) ??
              genericPhaseStart ??
              order?.updatedAt;
        }
        return null;
    }
  }

  DateTime? _resolveUpdatedAt(
    Map<String, dynamic> tableData,
    OrderModel? order,
  ) {
    return _readDate(tableData, const [
          'updated_at',
          'updatedAt',
          'last_update',
          'lastUpdate',
        ]) ??
        order?.updatedAt;
  }

  double _resolveAmount(
    Map<String, dynamic> tableData,
    OrderModel? order,
    TableState tableState,
  ) {
    if (tableState == TableState.free ||
        tableState == TableState.reserved ||
        tableState == TableState.unavailable) {
      return 0;
    }

    if (order != null && order.totalAmount > 0) {
      return order.totalAmount;
    }
    return _readDouble(tableData, const [
          'active_ticket_total',
          'activeTicketTotal',
          'total',
          'total_amount',
          'totalAmount',
          'amount',
        ]) ??
        0;
  }

  TableState _stateFromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.enCours:
      case OrderStatus.enPreparation:
      case OrderStatus.pret:
      case OrderStatus.servie:
      case OrderStatus.payee:
        return TableState.occupied;
      case OrderStatus.fermee:
        return TableState.cleaning;
      case OrderStatus.ingore:
        return TableState.free;
    }
  }

  TableServicePhase _phaseFromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.enCours:
        return TableServicePhase.orderTaken;
      case OrderStatus.enPreparation:
        return TableServicePhase.inKitchen;
      case OrderStatus.pret:
        return TableServicePhase.readyToServe;
      case OrderStatus.servie:
        return TableServicePhase.dining;
      case OrderStatus.payee:
        return TableServicePhase.paid;
      case OrderStatus.fermee:
        return TableServicePhase.cleaning;
      case OrderStatus.ingore:
        return TableServicePhase.none;
    }
  }

  TableState? _tableStateFromRaw(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    if (raw.contains('reserve') ||
        raw.contains('booked') ||
        raw.contains('booking')) {
      return TableState.reserved;
    }
    if (raw.contains('clean') || raw.contains('nettoy')) {
      return TableState.cleaning;
    }
    if (raw.contains('unavailable') ||
        raw.contains('indispo') ||
        raw.contains('mainten') ||
        raw.contains('out_of_service')) {
      return TableState.unavailable;
    }
    if (raw.contains('occup') ||
        raw.contains('busy') ||
        raw.contains('active') ||
        raw.contains('open') ||
        raw.contains('in_service')) {
      return TableState.occupied;
    }
    if (raw.contains('free') ||
        raw.contains('libre') ||
        raw.contains('available')) {
      return TableState.free;
    }
    return null;
  }

  TableServicePhase? _servicePhaseFromRaw(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    if (raw.contains('waiting') ||
        raw.contains('attente') ||
        raw.contains('without_order')) {
      return TableServicePhase.waitingForOrder;
    }
    if (raw.contains('order_taken') ||
        raw.contains('commande_prise') ||
        raw.contains('prise')) {
      return TableServicePhase.orderTaken;
    }
    if (raw.contains('kitchen') ||
        raw.contains('prep') ||
        raw.contains('cuisine')) {
      return TableServicePhase.inKitchen;
    }
    if (raw.contains('ready') || raw.contains('pret')) {
      return TableServicePhase.readyToServe;
    }
    if (raw.contains('dining') ||
        raw.contains('served') ||
        raw.contains('servie') ||
        raw.contains('repas')) {
      return TableServicePhase.dining;
    }
    if (raw.contains('paid') ||
        raw.contains('payee') ||
        raw.contains('settled') ||
        raw.contains('encaisse')) {
      return TableServicePhase.paid;
    }
    if (raw.contains('payment') ||
        raw.contains('reglement') ||
        raw.contains('checkout') ||
        raw.contains('payer')) {
      return TableServicePhase.payment;
    }
    if (raw.contains('clean') || raw.contains('nettoy')) {
      return TableServicePhase.cleaning;
    }
    if (raw.contains('free_again') || raw.contains('released')) {
      return TableServicePhase.freeAgain;
    }
    return null;
  }

  TableUrgencyLevel? _urgencyFromRaw(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    if (raw.contains('urgent') ||
        raw.contains('critical') ||
        raw.contains('high')) {
      return TableUrgencyLevel.urgent;
    }
    if (raw.contains('watch') ||
        raw.contains('attention') ||
        raw.contains('warning') ||
        raw.contains('medium')) {
      return TableUrgencyLevel.watch;
    }
    if (raw.contains('normal') ||
        raw.contains('ok') ||
        raw.contains('none') ||
        raw.contains('low')) {
      return TableUrgencyLevel.normal;
    }
    return null;
  }

  String _tableKeyFromDoc(
    Map<String, dynamic> data, {
    required String fallbackId,
  }) {
    final number = _readInt(data, const [
      'table_number',
      'tableNumber',
      'number',
    ]);
    if (number != null) {
      return number.toString();
    }

    final value = _readString(data, const [
      'label',
      'table',
      'table_id',
      'tableId',
      'name',
    ]);
    final extracted = _extractNumberFromText(value);
    if (extracted != null) {
      return extracted;
    }

    return _normalizeTableKey(fallbackId);
  }

  String _normalizeTableKey(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }

    final explicitDigits = RegExp(
      r'(?:table[\s:_-]*)?t?\s*0*(\d+)',
    ).firstMatch(value);
    if (explicitDigits != null) {
      return explicitDigits.group(1)!;
    }

    return value.replaceAll(RegExp(r'\s+'), '');
  }

  String? _extractNumberFromText(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    final match = RegExp(r'(\d+)').firstMatch(value);
    return match?.group(1);
  }

  int _sortFromDisplay(String display) {
    final numeric = int.tryParse(_extractNumberFromText(display) ?? '');
    return numeric ?? 999999;
  }

  String _elapsedLabel(DateTime? startedAt) {
    if (startedAt == null) {
      return '';
    }
    final now = DateTime.now();
    if (startedAt.isAfter(now)) {
      return '0 min';
    }

    final diff = now.difference(startedAt);
    final totalMinutes = math.max(0, diff.inMinutes);
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  String _formatAmount(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final groups = <String>[];
    for (var i = absolute.length; i > 0; i -= 3) {
      final start = math.max(0, i - 3);
      groups.insert(0, absolute.substring(start, i));
    }
    final grouped = groups.join(' ');
    return rounded < 0 ? '-$grouped' : grouped;
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

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' ||
            normalized == '1' ||
            normalized == 'yes' ||
            normalized == 'oui') {
          return true;
        }
        if (normalized == 'false' ||
            normalized == '0' ||
            normalized == 'no' ||
            normalized == 'non') {
          return false;
        }
      }
    }
    return null;
  }

  double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value
            .replaceAll('\u00A0', '')
            .replaceAll(' ', '')
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9.\-]'), '');
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      final parsed = _toDateTime(value);
      if (parsed != null) {
        return parsed;
      }
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
      final raw = value.round();
      final isMs = raw > 9999999999;
      return DateTime.fromMillisecondsSinceEpoch(
        isMs ? raw : raw * 1000,
      ).toLocal();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is Map) {
      final dynamic secondsRaw = value['_seconds'] ?? value['seconds'];
      final dynamic nanosRaw = value['_nanoseconds'] ?? value['nanoseconds'];
      if (secondsRaw is num) {
        final millis =
            (secondsRaw * 1000) +
            ((nanosRaw is num ? nanosRaw : 0).toDouble() / 1000000);
        return DateTime.fromMillisecondsSinceEpoch(millis.round()).toLocal();
      }
    }
    return null;
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final TablesViewMode selectedMode;
  final ValueChanged<TablesViewMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _ModeButton(
            icon: Icons.view_module_rounded,
            label: 'Liste',
            selected: selectedMode == TablesViewMode.list,
            onTap: () => onModeChanged(TablesViewMode.list),
          ),
          _ModeButton(
            icon: Icons.map_outlined,
            label: 'Plan',
            selected: selectedMode == TablesViewMode.floor,
            onTap: () => onModeChanged(TablesViewMode.floor),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF253241) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : const Color(0xFF4B5563),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
