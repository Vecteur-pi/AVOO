import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'offline_sync_controller.dart';

class OfflineSyncBanner extends StatelessWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSyncController>(
      builder: (context, syncController, _) {
        final state = syncController.bannerState;
        if (state == SyncBannerState.hidden) {
          return const SizedBox.shrink();
        }

        final style = _styleForState(state);
        // Position below the AppBar (approx 56px) + safe area
        final topPadding = MediaQuery.of(context).padding.top + 60;

        return Positioned(
          top: topPadding,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: style.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(style.icon, color: style.foreground, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      syncController.bannerMessage,
                      style: TextStyle(
                        color: style.foreground,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _BannerStyle _styleForState(SyncBannerState state) {
    switch (state) {
      case SyncBannerState.offline:
        return const _BannerStyle(
          background: Color(0xFFF9FAFB),
          border: Color(0xFFE5E7EB),
          foreground: Color(0xFF6B7280),
          icon: Icons.cloud_off_rounded,
        );
      case SyncBannerState.syncing:
        return const _BannerStyle(
          background: Color(0xFFEFF6FF),
          border: Color(0xFF60A5FA),
          foreground: Color(0xFF1D4ED8),
          icon: Icons.sync_rounded,
        );
      case SyncBannerState.synced:
        return const _BannerStyle(
          background: Color(0xFFECFDF5),
          border: Color(0xFF34D399),
          foreground: Color(0xFF047857),
          icon: Icons.cloud_done_rounded,
        );
      case SyncBannerState.hidden:
        return const _BannerStyle(
          background: Colors.transparent,
          border: Colors.transparent,
          foreground: Colors.transparent,
          icon: Icons.circle,
        );
    }
  }
}

class _BannerStyle {
  const _BannerStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
