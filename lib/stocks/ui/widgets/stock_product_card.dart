import 'package:flutter/material.dart';

import '../../models/stock_product.dart';

class StockProductCard extends StatelessWidget {
  const StockProductCard({
    super.key,
    required this.product,
    required this.displayedQuantity,
    required this.onIncrease,
    required this.onDecrease,
    required this.onMenuTap,
    this.readOnly = false,
  });

  final StockProduct product;
  final double displayedQuantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onMenuTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusFor(product.status);
    final minStock = product.minStock <= 0 ? 1 : product.minStock;
    final progressValue = (displayedQuantity / (minStock * 2)).clamp(0.0, 1.0);
    final quantityLabel = _formatQuantity(displayedQuantity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.isArchived) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Élément archivé',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusStyle.label,
                  style: TextStyle(
                    color: statusStyle.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: Key('stock_menu_${product.id}'),
                onPressed: onMenuTap,
                icon: const Icon(Icons.more_horiz_rounded),
                color: const Color(0xFFC0C6D0),
                tooltip: 'Actions',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                key: Key('stock_minus_${product.id}'),
                icon: Icons.remove_rounded,
                onTap: readOnly || product.isArchived ? null : onDecrease,
                activeColor: const Color(0xFFE9ECF0),
                iconColor: const Color(0xFF6B7280),
              ),
              const Spacer(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quantityLabel,
                    style: const TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.unit} restants',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _ActionButton(
                key: Key('stock_plus_${product.id}'),
                icon: Icons.add_rounded,
                onTap: readOnly || product.isArchived ? null : onIncrease,
                activeColor: const Color(0xFF146D36),
                iconColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const gap = 4.0;
              var filledWidth = totalWidth * progressValue;
              var emptyWidth = totalWidth - filledWidth;

              if (filledWidth > 0 && emptyWidth > 0) {
                filledWidth -= gap / 2;
                emptyWidth -= gap / 2;
              }

              return Row(
                children: [
                  if (filledWidth > 0)
                    Container(
                      height: 6,
                      width: filledWidth >= 0 ? filledWidth : 0,
                      decoration: BoxDecoration(
                        color: statusStyle.progress,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  if (filledWidth > 0 && emptyWidth > 0)
                    const SizedBox(width: gap),
                  if (emptyWidth > 0)
                    Container(
                      height: 6,
                      width: emptyWidth >= 0 ? emptyWidth : 0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EBF0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Seuil: ${_formatQuantity(product.minStock)} ${product.unit}',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Actu. ${_formatTime(product.lastUpdated)}',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static _StatusStyle _statusFor(StockStatus status) {
    switch (status) {
      case StockStatus.normal:
        return const _StatusStyle(
          label: 'Normal',
          background: Color(0xFFD4F2E2),
          foreground: Color(0xFF0E7A4A),
          progress: Color(0xFF2AA86A),
        );
      case StockStatus.low:
        return const _StatusStyle(
          label: 'Faible',
          background: Color(0xFFFBEFB8),
          foreground: Color(0xFFD97706),
          progress: Color(0xFFD97706),
        );
      case StockStatus.critical:
        return const _StatusStyle(
          label: 'Critique',
          background: Color(0xFFFCD8D8),
          foreground: Color(0xFFD32F2F),
          progress: Color(0xFFD32F2F),
        );
    }
  }

  static String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'aujourd\'hui $hour:$minute';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.activeColor,
    required this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isEnabled ? activeColor : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isEnabled ? iconColor : const Color(0xFFAAB2C0),
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.progress,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color progress;
}
