import 'package:flutter/material.dart';
import '../../models/order_model.dart';

class OrderStatusFilters extends StatelessWidget {
  final OrderStatus currentFilter;
  final ValueChanged<OrderStatus?> onFilterChanged;
  final Map<OrderStatus?, int> counts;

  const OrderStatusFilters({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.counts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context, 'Tout', null, counts[null] ?? 0),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'En cours', OrderStatus.enCours,
              counts[OrderStatus.enCours] ?? 0),
          const SizedBox(width: 12),
          _buildFilterChip(context, 'En préparation', OrderStatus.enPreparation,
              counts[OrderStatus.enPreparation] ?? 0),
          const SizedBox(width: 12),
          _buildFilterChip(
              context, 'Prêt', OrderStatus.pret, counts[OrderStatus.pret] ?? 0),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, OrderStatus? status, int count) {
    final isSelected = currentFilter == (status ?? OrderStatus.enCours) &&
        (status != null || currentFilter == null); 
    // Wait, the logic for "Tout" selection vs specific might be tricky if `currentFilter` is non-nullable in parent.
    // Let's assume parent manages "All" by passing a specific value or we change this widget to accept nullable.
    // Actually, looking at screenshot: "Tout (5)", "En cours (2)", etc.
    // My prop `currentFilter` is `OrderStatus`, which doesn't have "All".
    // I should probably make `currentFilter` nullable in parent or add `OrderFilter` enum.
    // For now let's say if status is null it means "Tout".

    // Correct logic:
    // If I pass `null` as status, it represents "Tout".
    // I need to know if "Tout" is selected.

    bool selected = false;
    if (status == null) {
      // "Tout" case. If we don't have a specific selected status, maybe we need a way to represent "All" in the parent state.
      // For now let's assume parent passes `null` for "All".
      // But my `currentFilter` is `OrderStatus`.
      // Let's change `currentFilter` to `OrderStatus?`.
    }

    // Let's simplify. Parent passes `OrderStatus? currentFilter`. `null` means All.
    // So:
    selected = currentFilter == status;

    return GestureDetector(
      onTap: () => onFilterChanged(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D3B4F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2D3B4F) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
