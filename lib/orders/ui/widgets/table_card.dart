import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';
import 'table_alert_badge.dart';
import 'table_status_chip.dart';

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.elapsedLabel,
    required this.amountLabel,
    this.onTap,
  });

  final TableOverviewModel table;
  final String elapsedLabel;
  final String amountLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stateStyle = tableStateStyle(table.tableState);
    final urgencyStyle = tableUrgencyStyle(table.urgencyLevel);
    final borderColor = table.hasAlert
        ? urgencyStyle.borderColor
        : stateStyle.borderColor;
    final hasPeople = table.guestCount > 0;
    final hasElapsed = elapsedLabel.isNotEmpty;
    final hasServerOrZone =
        table.serverName.trim().isNotEmpty || table.zoneName.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: stateStyle.baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Table ${table.tableNumber}',
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TableAlertBadge(urgencyLevel: table.urgencyLevel),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tableStateLabel(table.tableState),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: stateStyle.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: TableStatusChip(phase: table.servicePhase)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasPeople)
                    _MetaPill(
                      icon: Icons.people_alt_outlined,
                      label: '${table.guestCount} pers.',
                    ),
                  if (hasElapsed)
                    _MetaPill(
                      icon: Icons.schedule_rounded,
                      label: elapsedLabel,
                    ),
                ],
              ),
              if (hasServerOrZone) ...[
                const SizedBox(height: 8),
                Text(
                  _serverZoneLine(
                    serverName: table.serverName,
                    zoneName: table.zoneName,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
              const Spacer(),
              if (table.totalAmount > 0)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountLabel,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 1),
                      child: Text(
                        'FCFA',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _serverZoneLine({
    required String serverName,
    required String zoneName,
  }) {
    final parts = <String>[];
    if (serverName.trim().isNotEmpty) {
      parts.add('Serveur: ${serverName.trim()}');
    }
    if (zoneName.trim().isNotEmpty) {
      parts.add('Zone: ${zoneName.trim()}');
    }
    return parts.join(' | ');
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
