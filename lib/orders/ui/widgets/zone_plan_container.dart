import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';
import 'table_plan_card.dart';

class ZonePlanContainer extends StatelessWidget {
  const ZonePlanContainer({
    super.key,
    required this.zoneName,
    required this.tables,
    required this.onTableTap,
  });

  final String zoneName;
  final List<TableOverviewModel> tables;
  final ValueChanged<TableOverviewModel> onTableTap;

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const SizedBox.shrink();
    }

    final int freeCount = tables.where((t) => t.tableState == TableState.free).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF253241),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zoneName.isEmpty ? 'Sans Zone' : zoneName,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tables.length} tables',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$freeCount libres',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 20, endIndent: 20),
          // Grid Background with Items
          Stack(
            children: [
              // Decorative Grid Background
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _GridBackgroundPainter(),
                    ),
                  ),
                ),
              ),
              // Tables and Label
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: tables.map((table) {
                          return SizedBox(
                            width: 100, // Adjust this width as needed to fit 3 columns
                            child: TablePlanCard(
                              table: table,
                              index: tables.indexOf(table),
                              onTap: () => onTableTap(table),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          (zoneName.isEmpty ? 'SANS ZONE' : zoneName).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF9FAFB)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double cellSize = 45.0; // Adjust cell size as needed
    const double spacing = 4.0;
    const double cornerRadius = 6.0;

    for (double y = 0; y < size.height; y += cellSize + spacing) {
      for (double x = 0; x < size.width; x += cellSize + spacing) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          const Radius.circular(cornerRadius),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
