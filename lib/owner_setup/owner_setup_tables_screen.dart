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
  static const List<int> _presets = <int>[8, 10, 12, 16, 20];

  late int _tablesCount = widget.initialTablesCount
      .clamp(_minTables, _maxTables)
      .toInt();
  bool _confirming = false;

  int get _estimatedSeats => _tablesCount * 4;

  int get _insideTables {
    return (_tablesCount * 0.7).round();
  }

  int get _terraceTables {
    return _tablesCount - _insideTables;
  }

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _confirming
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AvooColors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: _displayProgress,
                    backgroundColor: const Color(0xFFB8C8AD),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AvooColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_displayCompletedSteps sur 4 étapes complétées',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2D3B4F),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ajouter les tables',
                  style: TextStyle(
                    color: AvooColors.navy,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  restaurantName,
                  style: const TextStyle(
                    color: Color(0xFF27364D),
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choisissez le nombre de tables',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AvooColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          _CounterActionButton(
                            icon: Icons.add_rounded,
                            enabled: _tablesCount < _maxTables,
                            onTap: () => _setTablesCount(_tablesCount + 1),
                          ),
                          const SizedBox(height: 10),
                          _CounterActionButton(
                            icon: Icons.remove_rounded,
                            enabled: _tablesCount > _minTables,
                            onTap: () => _setTablesCount(_tablesCount - 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_tablesCount',
                                style: const TextStyle(
                                  color: AvooColors.navy,
                                  fontSize: 92,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 2,
                                height: 90,
                                color: const Color(0xFFB2B9C1),
                              ),
                              const SizedBox(width: 12),
                              const RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  'tables',
                                  style: TextStyle(
                                    color: Color(0xFF6B7484),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    final selected = preset == _tablesCount;
                    return ChoiceChip(
                      label: Text('$preset tables'),
                      selected: selected,
                      onSelected: (_) => _setTablesCount(preset),
                      selectedColor: AvooColors.green,
                      backgroundColor: Colors.white.withOpacity(0.75),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF495569),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF527C3B)
                            : const Color(0xFFD2D9D0),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFE0C5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Aperçu de la salle',
                                style: TextStyle(
                                  color: AvooColors.navy,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '$_estimatedSeats places',
                                style: const TextStyle(
                                  color: Color(0xFF42556D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Suggestion: $_insideTables en salle, $_terraceTables en terrasse',
                          style: const TextStyle(
                            color: Color(0xFF4C5D74),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                _tablesCount,
                                (index) => _TablePreviewTile(
                                  highlight: (index + 1) % 6 == 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 68,
                  child: ElevatedButton(
                    onPressed: _confirming ? null : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AvooColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: _confirming
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Confirmer le nombre',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _confirming
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5C687A),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
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
          width: 76,
          height: 62,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F2F5) : const Color(0xFFE4E6EB),
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

class _TablePreviewTile extends StatelessWidget {
  const _TablePreviewTile({required this.highlight});

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFE7F0DF)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        Icons.table_restaurant_rounded,
        color: highlight ? const Color(0xFF4A7B3A) : const Color(0xFF516175),
        size: 25,
      ),
    );
  }
}
