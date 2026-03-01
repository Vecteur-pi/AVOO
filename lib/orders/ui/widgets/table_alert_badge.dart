import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';

class TableAlertBadge extends StatelessWidget {
  const TableAlertBadge({
    super.key,
    required this.urgencyLevel,
    this.showWhenNormal = false,
  });

  final TableUrgencyLevel urgencyLevel;
  final bool showWhenNormal;

  @override
  Widget build(BuildContext context) {
    if (urgencyLevel == TableUrgencyLevel.normal && !showWhenNormal) {
      return const SizedBox.shrink();
    }

    final style = tableUrgencyStyle(urgencyLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        tableUrgencyLabel(urgencyLevel),
        style: TextStyle(
          color: style.textColor,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
