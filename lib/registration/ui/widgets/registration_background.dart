import 'package:flutter/material.dart';

class RegistrationBackground extends StatelessWidget {
  const RegistrationBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _BaseGradient(),
        Positioned(top: -120, left: -80, child: _BlurBlob(size: 280)),
        Positioned(top: 160, right: -100, child: _BlurBlob(size: 260)),
        Positioned(bottom: -140, right: -40, child: _BlurBlob(size: 300)),
        Positioned(bottom: 80, left: -90, child: _BlurBlob(size: 240)),
      ],
    );
  }
}

class _BaseGradient extends StatelessWidget {
  const _BaseGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7FBFA),
            Color(0xFFE6F3EF),
            Color(0xFFF7F3E8),
          ],
        ),
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5CB3A5).withOpacity(0.16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5CB3A5).withOpacity(0.25),
            blurRadius: 80,
            offset: const Offset(0, 20),
          ),
        ],
      ),
    );
  }
}
