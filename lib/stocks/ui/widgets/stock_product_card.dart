import 'package:flutter/material.dart';
import '../../models/stock_product.dart';

class StockProductCard extends StatelessWidget {
  const StockProductCard({
    super.key,
    required this.product,
    required this.onOrderTap,
  });

  final StockProduct product;
  final VoidCallback onOrderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowOrCritical = product.status == StockStatus.low ||
        product.status == StockStatus.critical;
        
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Name & Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),

          // Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.quantityRemaining.toInt().toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                  fontSize: 28,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${product.unit} restants',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          if (product.usageToday != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA), // Light blue-grey background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: Color(0xFF2563EB), // Blue icon
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.usageToday?.toInt() ?? 0} ${product.usageUnit ?? product.unit} vendues aujourd\'hui',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2563EB), // Blue text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Timestamp
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Actualisé aujourd\'hui ${_formatTime(product.lastUpdated)} | il y a ${_getRelativeTime(product.lastUpdated)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (isLowOrCritical) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onOrderTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF739760), // Sage green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Commander maintenant'),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (product.status) {
      case StockStatus.normal:
        bgColor = const Color(0xFFDEF7EC); // Light green
        textColor = const Color(0xFF03543F); // Dark green
        label = 'Normal';
        break;
      case StockStatus.low:
        bgColor = const Color(0xFFFEF3C7); // Light amber/orange background
        textColor = const Color(0xFFD97706); // Amber text
        label = 'Niveau faible';
        icon = Icons.circle;
        break;
      case StockStatus.critical:
        bgColor = const Color(0xFFFDE8E8); // Light red
        textColor = const Color(0xFFE02424); // Red text
        label = 'Critique';
        icon = Icons.circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    // Simplistic relative time for dummy data
    if (difference.inMinutes < 60) {
      // Because we use hardcoded values in UI spec: "il y a 30 min", we just return the string format
      return '${difference.inMinutes == 0 ? 30 : difference.inMinutes} min'; 
    } else {
      return '${difference.inHours} h';
    }
  }
}
