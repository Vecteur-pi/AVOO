import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'staff_invite_accept_screen.dart';

class StaffInviteLinkListener extends StatefulWidget {
  const StaffInviteLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<StaffInviteLinkListener> createState() =>
      _StaffInviteLinkListenerState();
}

class _StaffInviteLinkListenerState extends State<StaffInviteLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _lastHandledInviteKey;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {
      // Ignore malformed initial links and continue listening.
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleIncomingUri,
      onError: (_) {
        // Ignore stream errors to avoid crashing the app.
      },
    );
  }

  void _handleIncomingUri(Uri uri) {
    final payload = StaffInvitePayload.fromUri(uri);
    if (payload == null) {
      return;
    }

    final inviteKey =
        '${payload.restaurantId}:${payload.invitationId}:${payload.token}';
    if (_lastHandledInviteKey == inviteKey) {
      return;
    }
    _lastHandledInviteKey = inviteKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              StaffInviteAcceptScreen(payload: payload, fromDeepLink: true),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
