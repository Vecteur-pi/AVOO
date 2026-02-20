import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class OwnerSetupTablesScreen extends StatefulWidget {
  const OwnerSetupTablesScreen({
    super.key,
    required this.restaurantName,
    required this.initialTablesCount,
    required this.completedStepsCount,
  });

  final String restaurantName;
  final int initialTablesCount;
  final int completedStepsCount;

  @override
  State<OwnerSetupTablesScreen> createState() => _OwnerSetupTablesScreenState();
}

class _OwnerSetupTablesScreenState extends State<OwnerSetupTablesScreen> {
  static const int _minTables = 1;
  static const int _maxTables = 60;

  late int _tablesCount = widget.initialTablesCount
      .clamp(_minTables, _maxTables)
      .toInt();
  bool _confirming = false;

  int get _displayCompletedSteps {
    final completed = widget.completedStepsCount;
    return completed < 2 ? 2 : completed;
  }

  double get _displayProgress {
    return (_displayCompletedSteps / 4).clamp(0.0, 1.0).toDouble();
  }

  void _setTablesCount(int value) {
    final sanitized = value.clamp(_minTables, _maxTables).toInt();
    if (_tablesCount == sanitized) return;
    setState(() {
      _tablesCount = sanitized;
    });
  }

  Future<void> _confirmSelection() async {
    if (_confirming) return;
    setState(() {
      _confirming = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(_tablesCount);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final restaurantName = widget.restaurantName.trim().isEmpty
        ? 'Votre restaurant'
        : widget.restaurantName.trim();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFD8E4D0),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: _displayProgress,
                        backgroundColor: const Color(0xFFB8C8AD),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AvooColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_displayCompletedSteps sur 4 étapes complétées',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2D3B4F),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  child: Column(
                    children: [
                      const Text(
                        'Ajouter les tables',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AvooColors.navy,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        restaurantName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4C5D74),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Choisissez le nombre de tables',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AvooColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8F9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CounterActionButton(
                                  icon: Icons.add_rounded,
                                  enabled: _tablesCount < _maxTables,
                                  onTap: () => _setTablesCount(_tablesCount + 1),
                                ),
                                const SizedBox(height: 8),
                                _CounterActionButton(
                                  icon: Icons.remove_rounded,
                                  enabled: _tablesCount > _minTables,
                                  onTap: () => _setTablesCount(_tablesCount - 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Container(
                              width: 2,
                              height: 100,
                              color: const Color(0xFFE0E3E8),
                            ),
                            Expanded(
                              child: Text(
                                '$_tablesCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AvooColors.navy,
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(
                          _tablesCount,
                          (index) => const _TablePreviewTile(),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirming ? null : _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AvooColors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _confirming
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirmer le nombre',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _confirming
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5C687A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterActionButton extends StatelessWidget {
  const _CounterActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 64,
          height: 54,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F3FD) : const Color(0xFFF1F3FD).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 32,
            color: enabled ? AvooColors.navy : const Color(0xFF98A0AC),
          ),
        ),
      ),
    );
  }
}

class _TablePreviewTile extends StatefulWidget {
  const _TablePreviewTile();

  @override
  State<_TablePreviewTile> createState() => _TablePreviewTileState();
}

class _TablePreviewTileState extends State<_TablePreviewTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Image.asset(
          'assets/images/table_isometric.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

