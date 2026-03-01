import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';

class TableStatusChip extends StatelessWidget {
  const TableStatusChip({super.key, required this.phase});

  final TableServicePhase phase;

  @override
  Widget build(BuildContext context) {
    if (phase == TableServicePhase.none) {
      return const SizedBox.shrink();
    }

    final style = tablePhaseStyle(phase);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tableServicePhaseIcon(phase), color: style.textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            tableServicePhaseLabel(phase),
            style: TextStyle(
              color: style.textColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
