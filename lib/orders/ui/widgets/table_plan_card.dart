import 'package:flutter/material.dart';

import '../../models/table_dashboard_models.dart';
import 'dart:math' as math;

class TablePlanCard extends StatefulWidget {
  const TablePlanCard({
    super.key,
    required this.table,
    required this.index,
    this.onTap,
  });

  final TableOverviewModel table;
  final int index;
  final VoidCallback? onTap;

  @override
  State<TablePlanCard> createState() => _TablePlanCardState();
}

class _TablePlanCardState extends State<TablePlanCard>
    with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _entryFadeAnimation;
  late Animation<Offset> _entrySlideAnimation;

  @override
  void initState() {
    super.initState();
    // Tap Animation
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );

    // Entry Animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _entryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entrySlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tapController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _tapController.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    _tapController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final stateStyle = tableStateStyle(widget.table.tableState);
    final borderColor = stateStyle.borderColor;
    final isFree = widget.table.tableState == TableState.free;

    return FadeTransition(
      opacity: _entryFadeAnimation,
      child: SlideTransition(
        position: _entrySlideAnimation,
        child: AnimatedScale(
          scale: _scaleAnimation.value,
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: _tapController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
            margin: const EdgeInsets.all(4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: stateStyle.baseColor.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Center Icon with dashed border
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                          painter: _DashedCirclePainter(
                            color: stateStyle.baseColor.withOpacity(0.5),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: isFree ? stateStyle.baseColor : const Color(0xFF111827),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Table Name
                      Text(
                        'T${widget.table.tableNumber}',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status or Guests
                      Text(
                        isFree ? 'Libre' : '${widget.table.guestCount} pers.',
                        style: TextStyle(
                          color: stateStyle.baseColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: stateStyle.baseColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.table.tableNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    const int dashCount = 20;
    final double dashAngle = (2 * math.pi) / (dashCount * 2);

    for (int i = 0; i < dashCount * 2; i += 2) {
      final double startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
