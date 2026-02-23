import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incident_model.dart';
import '../repository/incident_repository.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key, required this.restaurantId});

  final String restaurantId;

  static const Color _bg = Color(0xFFF5F6F3);
  static const Color _dark = Color(0xFF1A2B3C);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _sage = Color(0xFF739760);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final IncidentRepository _repository = IncidentRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _actioningId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _validate(IncidentModel incident) async {
    setState(() => _actioningId = incident.id);
    try {
      await _repository.validate(widget.restaurantId, incident.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la validation.')),
        );
      }
    } finally {
      if (mounted) setState(() => _actioningId = '');
    }
  }

  Future<void> _ignore(IncidentModel incident) async {
    setState(() => _actioningId = incident.id);
    try {
      await _repository.ignore(widget.restaurantId, incident.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')),
        );
      }
    } finally {
      if (mounted) setState(() => _actioningId = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IncidentsScreen._bg,
      body: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: IncidentsScreen._border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Incidents',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: IncidentsScreen._dark,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                // Date filter chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: IncidentsScreen._surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: IncidentsScreen._border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Aujourd'hui",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: IncidentsScreen._surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un incident...',
                  hintStyle: TextStyle(color: IncidentsScreen._muted, fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: IncidentsScreen._muted, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Incident list ──
          Expanded(
            child: StreamBuilder<List<IncidentModel>>(
              stream: _repository.watchAll(widget.restaurantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF739760)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: IncidentsScreen._muted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            color: IncidentsScreen._muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var incidents = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  incidents = incidents
                      .where((i) =>
                          i.title.toLowerCase().contains(_searchQuery) ||
                          i.description.toLowerCase().contains(_searchQuery) ||
                          i.tableLabel.toLowerCase().contains(_searchQuery) ||
                          i.incidentNumber.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                // Sort: pending first, then by createdAt desc
                incidents.sort((a, b) {
                  if (a.status == IncidentStatus.pending && b.status != IncidentStatus.pending) return -1;
                  if (b.status == IncidentStatus.pending && a.status != IncidentStatus.pending) return 1;
                  return b.createdAt.compareTo(a.createdAt);
                });

                if (incidents.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: incidents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return _IncidentCard(
                      incident: incident,
                      isActioning: _actioningId == incident.id,
                      onValidate: () => _validate(incident),
                      onIgnore: () => _ignore(incident),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EDE3),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF739760), size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun incident en attente',
            style: TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tout est sous contrôle 🎉',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Incident Card
// ─────────────────────────────────────────────

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.isActioning,
    required this.onValidate,
    required this.onIgnore,
  });

  final IncidentModel incident;
  final bool isActioning;
  final VoidCallback onValidate;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final isPending = incident.status == IncidentStatus.pending;
    final isValidated = incident.status == IncidentStatus.validated;

    // Compute elapsed time display
    final elapsed = incident.minutesElapsed;
    final elapsedText = elapsed >= 60
        ? '${elapsed ~/ 60} h ${elapsed % 60} min'
        : '$elapsed min';
    final timeText = DateFormat('HH:mm').format(incident.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: incident number + table + menu ──
            Row(
              children: [
                Text(
                  incident.incidentNumber,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF739760),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  incident.tableLabel,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                // Status badge (if resolved)
                if (!isPending)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isValidated
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isValidated ? 'Validé' : 'Ignoré',
                      style: TextStyle(
                        color: isValidated
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Icon(Icons.more_horiz_rounded,
                    color: const Color(0xFF9CA3AF), size: 22),
              ],
            ),
            const SizedBox(height: 8),

            // ── Title ──
            Text(
              incident.title.isEmpty ? '(Sans titre)' : incident.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // ── Description ──
            if (incident.description.isNotEmpty)
              Text(
                '"${incident.description}"',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 14),

            // ── Info row: icon + amount / elapsed + time ──
            Row(
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _categoryIcon(incident.category),
                    color: const Color(0xFF6B7280),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '+${_formatAmount(incident.totalAmount)} ',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const TextSpan(
                            text: 'FCFA',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          elapsedText,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Action buttons (only for pending) ──
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // Ignorer
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isActioning ? null : onIgnore,
                      icon: isActioning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6B7280),
                              ),
                            )
                          : const Icon(Icons.cancel_outlined,
                              size: 18, color: Color(0xFF4B5563)),
                      label: const Text(
                        'Ignorer',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Valider
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isActioning ? null : onValidate,
                      icon: isActioning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: Colors.white),
                      label: const Text(
                        'Valider',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF739760),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.drink:
        return Icons.local_bar_outlined;
      case IncidentCategory.food:
        return Icons.local_pizza_outlined;
      case IncidentCategory.other:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatAmount(double value) {
    if (value == 0) return '0';
    final rounded = value.round();
    final str = rounded.abs().toString();
    final groups = <String>[];
    for (var i = str.length; i > 0; i -= 3) {
      groups.insert(0, str.substring(i > 3 ? i - 3 : 0, i));
    }
    return groups.join(',');
  }
}
