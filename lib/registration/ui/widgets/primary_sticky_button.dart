import 'package:flutter/material.dart';

import '../../../theme/avoo_theme.dart';
import 'glow_button.dart';

class PrimaryStickyButton extends StatelessWidget {
  const PrimaryStickyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AvooColors.line, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AvooColors.softShadow,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlowButton(
            label: label,
            onPressed: onPressed,
            isLoading: isLoading,
          ),
          if (secondaryLabel != null && onSecondaryPressed != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : onSecondaryPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AvooColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  secondaryLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AvooColors.green,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
