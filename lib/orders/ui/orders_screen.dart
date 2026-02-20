import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For formatting Timestamp if needed, but we use Model
import '../models/order_model.dart';
import '../repository/order_repository.dart';
import 'widgets/order_card.dart';
import 'widgets/order_status_filters.dart';

class OrdersScreen extends StatefulWidget {
  final String restaurantId;

  const OrdersScreen({Key? key, required this.restaurantId}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderRepository _repository = OrderRepository();
  String _searchQuery = '';
  OrderStatus? _selectedStatus; // null means All

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      body: StreamBuilder<List<OrderModel>>(
        stream: _repository.getOrdersStream(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final allOrders = snapshot.data ?? [];

          // Calculate counts
          final counts = <OrderStatus?, int>{
            null: allOrders.length,
            OrderStatus.enCours:
                allOrders.where((o) => o.status == OrderStatus.enCours).length,
            OrderStatus.enPreparation: allOrders
                .where((o) => o.status == OrderStatus.enPreparation)
                .length,
            OrderStatus.pret:
                allOrders.where((o) => o.status == OrderStatus.pret).length,
          };

          // Filter
          var filteredOrders = allOrders;

          // 1. Status Filter
          if (_selectedStatus != null) {
            filteredOrders = filteredOrders
                .where((o) => o.status == _selectedStatus)
                .toList();
          }

          // 2. Search Filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredOrders = filteredOrders.where((o) {
              return o.tableNumber.toLowerCase().contains(query) ||
                  o.items.any((i) => i.name.toLowerCase().contains(query));
            }).toList();
          }

          return Column(
            children: [
              // Header & Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF5F6F3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commandes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Serif',
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Filter (Mocked for now)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "Aujourd'hui",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher une commande',
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterTab(
                            label: 'Tout',
                            count: counts[null]!,
                            isSelected: _selectedStatus == null,
                            onTap: () =>
                                setState(() => _selectedStatus = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'En cours',
                            count: counts[OrderStatus.enCours]!,
                            isSelected:
                                _selectedStatus == OrderStatus.enCours,
                            onTap: () => setState(
                                () => _selectedStatus = OrderStatus.enCours),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'En préparation',
                            count: counts[OrderStatus.enPreparation]!,
                            isSelected:
                                _selectedStatus == OrderStatus.enPreparation,
                            onTap: () => setState(() =>
                                _selectedStatus = OrderStatus.enPreparation),
                          ),
                          const SizedBox(width: 8),
                          _FilterTab(
                            label: 'Prêt',
                            count: counts[OrderStatus.pret]!,
                            isSelected: _selectedStatus == OrderStatus.pret,
                            onTap: () => setState(
                                () => _selectedStatus = OrderStatus.pret),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Orders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return OrderCard(
                      order: order,
                      onValidate: () {
                        // Advance status
                        OrderStatus nextStatus;
                        switch (order.status) {
                          case OrderStatus.enCours:
                            nextStatus = OrderStatus.enPreparation;
                            break;
                          case OrderStatus.enPreparation:
                            nextStatus = OrderStatus.pret;
                            break;
                          default:
                            return; // Already done or ignore
                        }
                        _repository.updateOrderStatus(order.id, nextStatus);
                      },
                      onIgnore: () {
                        _repository.ignoreOrder(order.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3B4F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D3B4F)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
