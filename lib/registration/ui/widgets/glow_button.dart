import 'package:flutter/material.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final gradient = const LinearGradient(
      colors: [Color(0xFF6FE1D5), Color(0xFF43B6A8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : const Color(0xFFBFD9D5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF6FE1D5).withOpacity(0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
