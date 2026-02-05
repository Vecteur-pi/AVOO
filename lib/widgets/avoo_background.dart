import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class AvooBackground extends StatelessWidget {
  const AvooBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F7F4), Color(0xFFF1F4EE), Color(0xFFF7F7F6)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _GlowCircle(
            size: 260,
            color: AvooColors.green.withOpacity(0.12),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -60,
          child: _GlowCircle(
            size: 300,
            color: AvooColors.orange.withOpacity(0.12),
          ),
        ),
        Positioned(
          top: 120,
          right: 40,
          child: _GlowCircle(
            size: 140,
            color: AvooColors.navy.withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 80,
            offset: const Offset(0, 20),
          ),
        ],
      ),
    );
  }
}
