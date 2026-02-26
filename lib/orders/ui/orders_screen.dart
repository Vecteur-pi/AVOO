import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../repository/order_repository.dart';
import 'widgets/order_card.dart';
import '../../sync/offline_sync_controller.dart';

const String _allOrderFilterId = 'all';
const String _enCoursFilterId = 'en_cours';
const String _enPreparationFilterId = 'en_preparation';
const String _pretFilterId = 'pret';

const List<_OrderFilterOption> _orderFilterOptions = [
  _OrderFilterOption(id: _allOrderFilterId, label: 'Tout', status: null),
  _OrderFilterOption(
    id: _enCoursFilterId,
    label: 'En cours',
    status: OrderStatus.enCours,
  ),
  _OrderFilterOption(
    id: _enPreparationFilterId,
    label: 'En préparation',
    status: OrderStatus.enPreparation,
  ),
  _OrderFilterOption(
    id: _pretFilterId,
    label: 'Prêt',
    status: OrderStatus.pret,
  ),
];

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderRepository _repository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();

  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: _repository.getOrdersStream(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF739760)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        return _buildContent(context, allOrders);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<OrderModel> allOrders) {
    final filteredOrders = _buildFilteredOrders(allOrders);
    final statusCounts = _statusCounts(allOrders);
    final hasStatusFilter = _selectedStatus != null;
    final statusLabel = _statusLabel(_selectedStatus);
    final searchQuery = _searchController.text.trim();
    final enCoursCount = statusCounts[OrderStatus.enCours] ?? 0;

    return ColoredBox(
      color: const Color(0xFFF5F6F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Commandes',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Serif',
                    letterSpacing: -0.5,
                    color: Color(0xFF111827),
                  ),
                ),
                if (enCoursCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFFE02424),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$enCoursCount en cours',
                          style: const TextStyle(
                            color: Color(0xFFE02424),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 390;
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: isCompact
                                ? 'Rechercher'
                                : 'Rechercher une commande',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF9CA3AF),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 46,
                              minHeight: 46,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(right: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showStatusFilterSheet(statusCounts),
                      child: Container(
                        width: isCompact ? 96 : 110,
                        height: 54,
                        decoration: BoxDecoration(
                          color: hasStatusFilter
                              ? const Color(0xFF1C2434)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasStatusFilter
                                ? const Color(0xFF1C2434)
                                : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: hasStatusFilter
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Statut',
                                  style: TextStyle(
                                    color: hasStatusFilter
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: allOrders.isEmpty
                ? _buildEmptyOrdersState()
                : filteredOrders.isEmpty
                ? _buildEmptyFilteredState(
                    searchQuery: searchQuery,
                    hasStatusFilter: hasStatusFilter,
                    statusLabel: statusLabel,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final syncController = context
                          .read<OfflineSyncController>();
                      return OrderCard(
                        order: order,
                        onValidate: () {
                          OrderStatus nextStatus;
                          switch (order.status) {
                            case OrderStatus.enCours:
                              nextStatus = OrderStatus.enPreparation;
                              break;
                            case OrderStatus.enPreparation:
                              nextStatus = OrderStatus.pret;
                              break;
                            default:
                              return;
                          }
                          if (!syncController.isOnline) {
                            syncController.noteFirestoreWriteQueued();
                          }
                          _repository.updateOrderStatus(order.id, nextStatus);
                        },
                        onIgnore: () {
                          if (!syncController.isOnline) {
                            syncController.noteFirestoreWriteQueued();
                          }
                          _repository.ignoreOrder(order.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<OrderModel> _buildFilteredOrders(List<OrderModel> allOrders) {
    final query = _searchController.text.toLowerCase().trim();

    return allOrders.where((order) {
      if (_selectedStatus != null && order.status != _selectedStatus) {
        return false;
      }
      if (query.isEmpty) return true;

      final matchesTable = order.tableNumber.toLowerCase().contains(query);
      final matchesItem = order.items.any(
        (item) => item.name.toLowerCase().contains(query),
      );
      return matchesTable || matchesItem;
    }).toList();
  }

  Map<OrderStatus?, int> _statusCounts(List<OrderModel> allOrders) {
    return {
      null: allOrders.length,
      OrderStatus.enCours: allOrders
          .where((order) => order.status == OrderStatus.enCours)
          .length,
      OrderStatus.enPreparation: allOrders
          .where((order) => order.status == OrderStatus.enPreparation)
          .length,
      OrderStatus.pret: allOrders
          .where((order) => order.status == OrderStatus.pret)
          .length,
    };
  }

  String _statusLabel(OrderStatus? status) {
    switch (status) {
      case OrderStatus.enCours:
        return 'En cours';
      case OrderStatus.enPreparation:
        return 'En préparation';
      case OrderStatus.pret:
        return 'Prêt';
      default:
        return 'Tout';
    }
  }

  Widget _buildEmptyOrdersState() {
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF9CA3AF),
                size: 32,
              ),
              SizedBox(height: 12),
              Text(
                'Aucune commande pour le moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
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

  Widget _buildEmptyFilteredState({
    required String searchQuery,
    required bool hasStatusFilter,
    required String statusLabel,
  }) {
    final activeParts = <String>[];
    if (hasStatusFilter) {
      activeParts.add('statut "$statusLabel"');
    }
    if (searchQuery.isNotEmpty) {
      activeParts.add('recherche "$searchQuery"');
    }
    final description = activeParts.isEmpty
        ? 'Aucune commande pour ce filtre.'
        : 'Aucun résultat pour ${activeParts.join(' + ')}.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: Color(0xFF9CA3AF),
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasStatusFilter || searchQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStatusFilterSheet(
    Map<OrderStatus?, int> statusCounts,
  ) async {
    final selectedOption = _orderFilterOptions.where(
      (option) => option.status == _selectedStatus,
    );
    var tempFilterId = selectedOption.isEmpty
        ? _allOrderFilterId
        : selectedOption.first.id;

    final resultFilterId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomSafe = MediaQuery.of(sheetContext).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomSafe),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtres',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(
                                () => tempFilterId = _allOrderFilterId,
                              );
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Statut commande',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _orderFilterOptions
                            .map((option) {
                              final isSelected = option.id == tempFilterId;
                              final count = statusCounts[option.status] ?? 0;
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setModalState(() => tempFilterId = option.id);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1C2434)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1C2434)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    '${option.label} ($count)',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop(tempFilterId);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF146D36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Appliquer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (resultFilterId == null || !mounted) return;
    final selected = _orderFilterOptions.firstWhere(
      (option) => option.id == resultFilterId,
      orElse: () => _orderFilterOptions.first,
    );
    setState(() {
      _selectedStatus = selected.status;
    });
  }
}

class _OrderFilterOption {
  const _OrderFilterOption({
    required this.id,
    required this.label,
    required this.status,
  });

  final String id;
  final String label;
  final OrderStatus? status;
}
