import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../models/table_dashboard_models.dart';
import 'table_alert_badge.dart';
import 'table_status_chip.dart';

typedef TableStatusUpdateCallback =
    Future<bool> Function(TableState tableState, TableServicePhase phase);

class TableDetailsSheet extends StatefulWidget {
  const TableDetailsSheet({
    super.key,
    required this.table,
    required this.elapsedLabel,
    required this.amountLabel,
    this.canUpdateStatus = false,
    this.onStatusUpdate,
  });

  final TableOverviewModel table;
  final String elapsedLabel;
  final String amountLabel;
  final bool canUpdateStatus;
  final TableStatusUpdateCallback? onStatusUpdate;

  @override
  State<TableDetailsSheet> createState() => _TableDetailsSheetState();
}

class _TableDetailsSheetState extends State<TableDetailsSheet> {
  late TableState _selectedState;
  late TableServicePhase _selectedPhase;
  late TableState _savedState;
  late TableServicePhase _savedPhase;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _syncStatusFromTable();
  }

  @override
  void didUpdateWidget(covariant TableDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.tableId != widget.table.tableId ||
        oldWidget.table.updatedAt != widget.table.updatedAt) {
      _syncStatusFromTable();
    }
  }

  void _syncStatusFromTable() {
    _selectedState = widget.table.tableState;
    _selectedPhase = widget.table.servicePhase;
    _savedState = widget.table.tableState;
    _savedPhase = widget.table.servicePhase;
  }

  bool get _hasPendingStatusChange {
    return _selectedState != _savedState || _selectedPhase != _savedPhase;
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final stateStyle = tableStateStyle(_selectedState);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Table ${table.tableNumber}',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    TableAlertBadge(
                      urgencyLevel: table.urgencyLevel,
                      showWhenNormal: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stateStyle.surfaceColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: stateStyle.borderColor),
                      ),
                      child: Text(
                        tableStateLabel(_selectedState),
                        style: TextStyle(
                          color: stateStyle.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedPhase != TableServicePhase.none)
                      TableStatusChip(phase: _selectedPhase),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailsGrid(
                  children: [
                    _MetricCard(
                      title: 'Couverts',
                      value: table.guestCount > 0 ? '${table.guestCount}' : '-',
                      icon: Icons.people_alt_outlined,
                    ),
                    _MetricCard(
                      title: 'Temps',
                      value: widget.elapsedLabel.isEmpty
                          ? '-'
                          : widget.elapsedLabel,
                      icon: Icons.schedule_rounded,
                    ),
                    _MetricCard(
                      title: 'Total',
                      value: table.totalAmount > 0
                          ? '${widget.amountLabel} FCFA'
                          : '-',
                      icon: Icons.payments_rounded,
                    ),
                    _MetricCard(
                      title: 'Serveur',
                      value: table.serverName.isEmpty ? '-' : table.serverName,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
                if (table.zoneName.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Zone: ${table.zoneName.trim()}',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Details commande',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (table.orderItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'Aucun article actif. Les details apparaissent ici apres selection de la table.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Column(
                    children: table.orderItems
                        .map((item) => _OrderLine(item: item))
                        .toList(growable: false),
                  ),
                const SizedBox(height: 18),
                const Text(
                  'Historique rapide',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _TimelineRow(
                  label: 'Debut phase',
                  value: _formatDateTime(table.phaseStartedAt),
                ),
                _TimelineRow(
                  label: 'Derniere mise a jour',
                  value: _formatDateTime(table.updatedAt),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Changer etat table',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TableState>(
                  value: _selectedState,
                  isExpanded: true,
                  decoration: _fieldDecoration('Etat'),
                  items: TableState.values
                      .map(
                        (state) => DropdownMenuItem<TableState>(
                          value: state,
                          child: Text(
                            tableStateLabel(state),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (!widget.canUpdateStatus || _isSaving)
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          final supportedPhases = _phasesFor(value);
                          setState(() {
                            _selectedState = value;
                            if (!supportedPhases.contains(_selectedPhase)) {
                              _selectedPhase = _defaultPhaseFor(value);
                            }
                          });
                        },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TableServicePhase>(
                  value: _selectedPhase,
                  isExpanded: true,
                  decoration: _fieldDecoration('Phase service'),
                  items: _phasesFor(_selectedState)
                      .map(
                        (phase) => DropdownMenuItem<TableServicePhase>(
                          value: phase,
                          child: Text(
                            tableServicePhaseLabel(phase),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (!widget.canUpdateStatus || _isSaving)
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedPhase = value;
                          });
                        },
                ),
                if (!widget.canUpdateStatus) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Etat non modifiable ici (table non configuree dans la collection tables).',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (!widget.canUpdateStatus ||
                            widget.onStatusUpdate == null ||
                            _isSaving ||
                            !_hasPendingStatusChange)
                        ? null
                        : _submitStatusUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
                      disabledForegroundColor: const Color(0xFF9CA3AF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer etat',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickActionsFor(_selectedPhase)
                      .map(
                        (action) => OutlinedButton(
                          onPressed: (!widget.canUpdateStatus || _isSaving)
                              ? null
                              : () => _applyQuickAction(action),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            action.label,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  List<TableServicePhase> _phasesFor(TableState state) {
    switch (state) {
      case TableState.free:
      case TableState.reserved:
      case TableState.unavailable:
        return const [TableServicePhase.none];
      case TableState.occupied:
        return const [
          TableServicePhase.waitingForOrder,
          TableServicePhase.orderTaken,
          TableServicePhase.inKitchen,
          TableServicePhase.readyToServe,
          TableServicePhase.dining,
          TableServicePhase.payment,
          TableServicePhase.paid,
          TableServicePhase.none,
        ];
      case TableState.cleaning:
        return const [
          TableServicePhase.cleaning,
          TableServicePhase.freeAgain,
          TableServicePhase.none,
        ];
    }
  }

  TableServicePhase _defaultPhaseFor(TableState state) {
    switch (state) {
      case TableState.free:
      case TableState.reserved:
      case TableState.unavailable:
        return TableServicePhase.none;
      case TableState.occupied:
        return TableServicePhase.waitingForOrder;
      case TableState.cleaning:
        return TableServicePhase.cleaning;
    }
  }

  Future<void> _submitStatusUpdate() async {
    final callback = widget.onStatusUpdate;
    if (callback == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await callback(_selectedState, _selectedPhase);
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      if (success) {
        _savedState = _selectedState;
        _savedPhase = _selectedPhase;
      }
    });
  }

  Future<void> _applyQuickAction(_QuickAction action) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _selectedState = action.state;
      _selectedPhase = action.phase;
    });
    await _submitStatusUpdate();
  }

  List<_QuickAction> _quickActionsFor(TableServicePhase phase) {
    switch (phase) {
      case TableServicePhase.waitingForOrder:
        return const [
          _QuickAction(
            label: 'Prendre commande',
            state: TableState.occupied,
            phase: TableServicePhase.orderTaken,
          ),
          _QuickAction(
            label: 'Passer en cuisine',
            state: TableState.occupied,
            phase: TableServicePhase.inKitchen,
          ),
        ];
      case TableServicePhase.orderTaken:
        return const [
          _QuickAction(
            label: 'Passer en cuisine',
            state: TableState.occupied,
            phase: TableServicePhase.inKitchen,
          ),
          _QuickAction(
            label: 'Marquer pret',
            state: TableState.occupied,
            phase: TableServicePhase.readyToServe,
          ),
        ];
      case TableServicePhase.inKitchen:
        return const [
          _QuickAction(
            label: 'Marquer pret',
            state: TableState.occupied,
            phase: TableServicePhase.readyToServe,
          ),
          _QuickAction(
            label: 'Marquer servi',
            state: TableState.occupied,
            phase: TableServicePhase.dining,
          ),
        ];
      case TableServicePhase.readyToServe:
        return const [
          _QuickAction(
            label: 'Marquer servi',
            state: TableState.occupied,
            phase: TableServicePhase.dining,
          ),
          _QuickAction(
            label: 'Demander paiement',
            state: TableState.occupied,
            phase: TableServicePhase.payment,
          ),
        ];
      case TableServicePhase.dining:
        return const [
          _QuickAction(
            label: 'Demander paiement',
            state: TableState.occupied,
            phase: TableServicePhase.payment,
          ),
          _QuickAction(
            label: 'Marquer payee',
            state: TableState.occupied,
            phase: TableServicePhase.paid,
          ),
        ];
      case TableServicePhase.payment:
        return const [
          _QuickAction(
            label: 'Marquer payee',
            state: TableState.occupied,
            phase: TableServicePhase.paid,
          ),
          _QuickAction(
            label: 'Demarrer nettoyage',
            state: TableState.cleaning,
            phase: TableServicePhase.cleaning,
          ),
        ];
      case TableServicePhase.paid:
        return const [
          _QuickAction(
            label: 'Demarrer nettoyage',
            state: TableState.cleaning,
            phase: TableServicePhase.cleaning,
          ),
        ];
      case TableServicePhase.cleaning:
        return const [
          _QuickAction(
            label: 'Marquer libre',
            state: TableState.free,
            phase: TableServicePhase.none,
          ),
        ];
      case TableServicePhase.freeAgain:
      case TableServicePhase.none:
        return const [
          _QuickAction(
            label: 'Marquer occupee',
            state: TableState.occupied,
            phase: TableServicePhase.waitingForOrder,
          ),
          _QuickAction(
            label: 'Marquer reservee',
            state: TableState.reserved,
            phase: TableServicePhase.none,
          ),
          _QuickAction(
            label: 'Marquer indisponible',
            state: TableState.unavailable,
            phase: TableServicePhase.none,
          ),
        ];
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }
    final local = dateTime.toLocal();
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.state,
    required this.phase,
  });

  final String label;
  final TableState state;
  final TableServicePhase phase;
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: children,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name.trim().isEmpty ? 'Article' : item.name.trim(),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
