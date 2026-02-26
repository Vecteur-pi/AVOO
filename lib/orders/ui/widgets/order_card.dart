import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onValidate;
  final VoidCallback onIgnore;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onValidate,
    required this.onIgnore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tableLabel = _formatTableLabel(order.tableNumber);
    final now = DateTime.now();
    final timeAgo = now.difference(order.updatedAt);
    String timeAgoString;
    if (timeAgo.inMinutes < 60) {
      timeAgoString = 'il y a ${timeAgo.inMinutes} min';
    } else {
      timeAgoString = 'il y a ${timeAgo.inHours} h';
    }

    // Calculate delay
    // final now = DateTime.now(); // Already defined above
    final elapsedMinutes = now.difference(order.createdAt).inMinutes;
    final delay = elapsedMinutes - order.expectedPreparationTimeMinutes;

    // Only show if there is a delay or just show plain elapsed if no delay?
    // Requirement: "to highlight how much time has passed / delay relative to expectations"
    // Example: "+12 min". This usually implies 12 min OVER expectation.
    // If delay is negative (early), maybe hide or show different?
    // Let's assume positive delay is what we want to highlight with Red/Orange.

    String delayText;
    Color delayBgColor;

    if (delay > 0) {
      delayText = '+${delay} min';
      delayBgColor = const Color(0xFFEF4444); // Red for delay
    } else {
      // On time or early
      delayText = 'On time';
      delayBgColor = const Color(0xFF10B981); // Green
    }

    // Determine header color based on status
    Color headerColor;
    String statusText;
    switch (order.status) {
      case OrderStatus.enCours:
        headerColor = const Color(0xFFE27D60); // Burnt Orange
        statusText = 'En cours';
        break;
      case OrderStatus.enPreparation:
        headerColor = const Color(0xFFF39C12); // Orange/Yellow
        statusText = 'En préparation';
        break;
      case OrderStatus.pret:
        headerColor = const Color(0xFF739760); // Green
        statusText = 'Prêt';
        break;
      default:
        headerColor = Colors.grey;
        statusText = 'Inconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      tableLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: delayBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    delayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: order.items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item.name}${item.quantity > 1 ? ' x${item.quantity}' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Timestamp
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Actualisé aujourd\'hui ${DateFormat('HH:mm').format(order.updatedAt)} | $timeAgoString',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onIgnore,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ignorer',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onValidate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF739760),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Valider',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTableLabel(String rawTableNumber) {
    final value = rawTableNumber.trim();
    if (value.isEmpty) {
      return 'TABLE ?';
    }

    if (value.toLowerCase().startsWith('table')) {
      return value.toUpperCase();
    }

    return 'TABLE ${value.toUpperCase()}';
  }
}
