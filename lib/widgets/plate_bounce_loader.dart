import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable custom loader that animates a plate image with a smooth infinite
/// vertical bounce, a subtle tilt, and a slight scale pulse.
class PlateBounceLoader extends StatefulWidget {
  const PlateBounceLoader({
    super.key,
    this.size = 140.0,
  });

  /// The size of the loader image.
  final double size;

  @override
  State<PlateBounceLoader> createState() => _PlateBounceLoaderState();
}

class _PlateBounceLoaderState extends State<PlateBounceLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Loop duration of ~1200ms for a relaxed, natural feel.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start the infinite loop.
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the current phase of the animation loop (0.0 to 2*PI)
        final animationValue = _controller.value * 2 * math.pi;

        // Bounce up and down. Sine wave creates smooth easing at the top and bottom.
        // Multiply by 8 to get a max bounce height of 8 pixels.
        final bounceOffset = math.sin(animationValue) * 8.0;

        // Tilt back and forth. Cosine wave offsets the tilt slightly from the bounce
        // for a more complex, natural feeling motion.
        // 4 degrees converted to radians.
        final tiltAngle = math.cos(animationValue) * (4 * math.pi / 180);

        // Scale pulse. A very subtle squeeze and stretch.
        final scale = 1.0 + (math.sin(animationValue * 2) * 0.05);

        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: Transform.rotate(
            angle: tiltAngle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/Loading.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
