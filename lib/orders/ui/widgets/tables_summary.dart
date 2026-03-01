import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';

class TablesSummary extends StatelessWidget {
  const TablesSummary({
    super.key,
    required this.chipsData,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  final List<SummaryChipData> chipsData;
  final String selectedZone;
  final ValueChanged<String> onZoneSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chipsData
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SummaryChip(
                  data: chip,
                  selected: chip.id == selectedZone,
                  onTap: () => onZoneSelected(chip.id),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class SummaryChipData {
  const SummaryChipData({
    required this.id,
    required this.label,
    required this.count,
  });

  final String id;
  final String label;
  final int count;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final SummaryChipData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? const Color(0xFF253241) // Navy blue from design
        : Colors.white;
    final borderColor = selected
        ? const Color(0xFF253241)
        : const Color(0xFFE5E7EB);
    final textColor = selected ? Colors.white : const Color(0xFF4B5563);
    final countColor = selected ? Colors.white : const Color(0xFF111827);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data.count}',
                style: TextStyle(
                  color: countColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
