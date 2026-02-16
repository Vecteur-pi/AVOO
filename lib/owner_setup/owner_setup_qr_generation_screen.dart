import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';
import 'owner_setup_service.dart';

enum _QrGenerationState { generating, success, failed }

class OwnerSetupQrGenerationScreen extends StatefulWidget {
  const OwnerSetupQrGenerationScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.tablesCount,
    required this.service,
  });

  final String restaurantId;
  final String restaurantName;
  final int tablesCount;
  final OwnerSetupService service;

  @override
  State<OwnerSetupQrGenerationScreen> createState() =>
      _OwnerSetupQrGenerationScreenState();
}

class _OwnerSetupQrGenerationScreenState
    extends State<OwnerSetupQrGenerationScreen> {
  late final int _totalTablesCount = widget.tablesCount < 1
      ? 1
      : widget.tablesCount;

  _QrGenerationState _state = _QrGenerationState.generating;
  int _createdCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });
  }

  Future<void> _startGeneration() async {
    if (!mounted) return;
    setState(() {
      _state = _QrGenerationState.generating;
      _createdCount = 0;
      _errorMessage = null;
    });

    try {
      await widget.service.generateQRCodesForTables(
        restaurantId: widget.restaurantId,
        onProgress: (created, total) {
          if (!mounted) return;
          setState(() {
            _createdCount = created;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _state = _QrGenerationState.success;
        _createdCount = _totalTablesCount;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _QrGenerationState.failed;
        _errorMessage = _errorToMessage(error);
      });
    }
  }

  String _errorToMessage(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Permissions insuffisantes pour créer les QR codes.';
      }
      return 'Erreur Firebase: ${error.message ?? error.code}';
    }
    if (error is StateError && error.message != null) {
      return error.message.toString();
    }
    return 'Impossible de créer les QR codes. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final restaurantName = widget.restaurantName.trim().isEmpty
        ? 'Votre restaurant'
        : widget.restaurantName.trim();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: WillPopScope(
        onWillPop: () async => _state != _QrGenerationState.generating,
        child: Scaffold(
          backgroundColor: const Color(0xFFD8E4D0),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: _state == _QrGenerationState.generating
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AvooColors.green,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 26),
                        SizedBox(width: 8),
                        Text(
                          'Retour',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.86),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _buildContent(restaurantName),
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
    );
  }

  Widget _buildContent(String restaurantName) {
    switch (_state) {
      case _QrGenerationState.generating:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1DE),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AvooColors.green,
                size: 52,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Création des QR codes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AvooColors.navy,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              restaurantName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF445169),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            LinearProgressIndicator(
              minHeight: 10,
              value: _totalTablesCount == 0
                  ? 0
                  : _createdCount / _totalTablesCount,
              backgroundColor: const Color(0xFFD8E0D5),
              valueColor: const AlwaysStoppedAnimation<Color>(AvooColors.green),
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 14),
            Text(
              '$_createdCount / $_totalTablesCount tables configurées',
              style: const TextStyle(
                color: Color(0xFF42546A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(AvooColors.green),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez patienter...',
              style: TextStyle(
                color: Color(0xFF708099),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

      case _QrGenerationState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1DE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AvooColors.green,
                size: 58,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'QR codes créés',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AvooColors.navy,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_totalTablesCount QR codes enregistrés dans Firebase',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3F5167),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

      case _QrGenerationState.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF7E6E2),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB23B2A),
                size: 52,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Échec de génération',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AvooColors.navy,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5A6677),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: _startGeneration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvooColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A6677),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
    }
  }
}
