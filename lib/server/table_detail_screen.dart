import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../auth/user_profile.dart';
import '../theme/avoo_theme.dart';
import 'menu_picker_sheet.dart';

class TableDetailScreen extends StatefulWidget {
  const TableDetailScreen({
    super.key,
    required this.profile,
    required this.tableId,
    required this.tableName,
  });

  final UserProfile profile;
  final String tableId;
  final String tableName;

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final _guestsController = TextEditingController(text: '2');
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _guestsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _tableRef =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.profile.restaurantId)
          .collection('tables')
          .doc(widget.tableId);

  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.profile.restaurantId)
          .collection('tickets');

  Future<void> _createTicket() async {
    if (_busy) return;
    final guests = int.tryParse(_guestsController.text.trim()) ?? 0;
    if (guests <= 0) {
      _showSnack('Veuillez indiquer le nombre de couverts.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ticketRef = _ticketsRef.doc();
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();
      batch.set(ticketRef, {
        'table_id': widget.tableId,
        'table_label': widget.tableName,
        'guests': guests,
        'note': _noteController.text.trim(),
        'status': 'open',
        'closed': false,
        'created_at': now,
        'updated_at': now,
        'created_by': widget.profile.uid,
        'created_by_name': widget.profile.name,
      });
      batch.set(
        _tableRef,
        {
          'status': 'occupied',
          'active_ticket_id': ticketRef.id,
          'active_ticket_status': 'open',
          'updated_at': now,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      _noteController.clear();
      _showSnack('Ticket créé.');
    } catch (e) {
      _showSnack('Impossible de créer le ticket.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendTicket(DocumentReference<Map<String, dynamic>> ticketRef) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();
      batch.update(ticketRef, {
        'status': 'sent',
        'sent_at': now,
        'updated_at': now,
      });
      batch.set(
        _tableRef,
        {
          'status': 'ordered',
          'active_ticket_status': 'sent',
          'updated_at': now,
        },
        SetOptions(merge: true),
      );
      final items = await ticketRef
          .collection('items')
          .where('status', isEqualTo: 'draft')
          .get();
      for (final item in items.docs) {
        batch.update(item.reference, {
          'status': 'sent',
          'sent_at': now,
          'updated_at': now,
        });
      }
      await batch.commit();
      _showSnack('Commande envoyée.');
    } catch (e) {
      _showSnack('Erreur lors de l’envoi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestBill(
    DocumentReference<Map<String, dynamic>> ticketRef,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();
      batch.update(ticketRef, {
        'status': 'payment_requested',
        'payment_requested_at': now,
        'updated_at': now,
      });
      batch.set(
        _tableRef,
        {
          'status': 'payment',
          'active_ticket_status': 'payment_requested',
          'updated_at': now,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      _showSnack('Addition demandée.');
    } catch (e) {
      _showSnack('Erreur lors de la demande d’addition.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeTicket(
    DocumentReference<Map<String, dynamic>> ticketRef,
  ) async {
    if (_busy) return;
    final confirmed = await _confirm(
      title: 'Clôturer la table ?',
      message: 'Cette action ferme définitivement le ticket.',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();
      batch.update(ticketRef, {
        'status': 'closed',
        'closed': true,
        'closed_at': now,
        'updated_at': now,
      });
      batch.set(
        _tableRef,
        {
          'status': 'free',
          'active_ticket_id': FieldValue.delete(),
          'active_ticket_status': FieldValue.delete(),
          'updated_at': now,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      _showSnack('Table clôturée.');
    } catch (e) {
      _showSnack('Erreur lors de la clôture.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markServed(
    DocumentReference<Map<String, dynamic>> itemRef,
  ) async {
    try {
      await itemRef.update({
        'status': 'served',
        'served_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnack('Impossible de mettre à jour l’article.');
    }
  }

  Future<bool> _confirm({required String title, required String message}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketStream = _ticketsRef
        .where('table_id', isEqualTo: widget.tableId)
        .snapshots();

    return Scaffold(
      backgroundColor: AvooColors.bone,
      appBar: AppBar(
        title: Text(widget.tableName),
        backgroundColor: AvooColors.bone,
        foregroundColor: AvooColors.ink,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ticketStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement.'));
          }
          final docs = (snapshot.data?.docs ?? [])
              .where((doc) => (doc.data()['closed'] ?? false) == false)
              .toList();
          if (docs.isEmpty) {
            return _NoTicketView(
              guestsController: _guestsController,
              noteController: _noteController,
              busy: _busy,
              onCreate: _createTicket,
            );
          }

          docs.sort((a, b) {
            final aTime = a.data()['created_at'] as Timestamp?;
            final bTime = b.data()['created_at'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          final ticketDoc = docs.first;
          final data = ticketDoc.data();
          final status = (data['status'] ?? 'open').toString();
          final guestsRaw = data['guests'];
          final guests = guestsRaw is num ? guestsRaw.toInt() : 0;

          return _ActiveTicketView(
            ticketRef: ticketDoc.reference,
            ticketStatus: status,
            guests: guests,
            onSend: () => _sendTicket(ticketDoc.reference),
            onRequestBill: () => _requestBill(ticketDoc.reference),
            onClose: () => _closeTicket(ticketDoc.reference),
            onMarkServed: _markServed,
            onAddItems: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AvooColors.bone,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => MenuPickerSheet(
                  restaurantId: widget.profile.restaurantId,
                  ticketRef: ticketDoc.reference,
                  ticketStatus: status,
                  serverId: widget.profile.uid,
                  serverName: widget.profile.name,
                ),
              );
            },
            busy: _busy,
          );
        },
      ),
    );
  }
}

class _NoTicketView extends StatelessWidget {
  const _NoTicketView({
    required this.guestsController,
    required this.noteController,
    required this.busy,
    required this.onCreate,
  });

  final TextEditingController guestsController;
  final TextEditingController noteController;
  final bool busy;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Créer un ticket',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: guestsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Couverts',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: busy ? null : onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AvooColors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(busy ? 'Création...' : 'Créer le ticket'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTicketView extends StatelessWidget {
  const _ActiveTicketView({
    required this.ticketRef,
    required this.ticketStatus,
    required this.guests,
    required this.onSend,
    required this.onRequestBill,
    required this.onClose,
    required this.onAddItems,
    required this.onMarkServed,
    required this.busy,
  });

  final DocumentReference<Map<String, dynamic>> ticketRef;
  final String ticketStatus;
  final int guests;
  final VoidCallback onSend;
  final VoidCallback onRequestBill;
  final VoidCallback onClose;
  final VoidCallback onAddItems;
  final Future<void> Function(DocumentReference<Map<String, dynamic>>) onMarkServed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final itemsStream =
        ticketRef.collection('items').orderBy('created_at').snapshots();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Couverts: $guests',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ticketStatusLabel(ticketStatus),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _ticketStatusColor(ticketStatus),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: busy ? null : onAddItems,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvooColors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: itemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Erreur lors du chargement.'));
              }
              final items = snapshot.data?.docs ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Aucun article ajouté.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = items[index];
                  final data = doc.data();
                  final name = (data['name'] ?? data['label'] ?? 'Article').toString();
                  final qtyRaw = data['quantity'];
                  final qty = qtyRaw is num ? qtyRaw.toInt() : 1;
                  final note = (data['notes'] ?? data['note'] ?? '').toString();
                  final route =
                      (data['route'] ?? data['station'] ?? data['routage'] ?? '')
                          .toString();
                  final status = (data['status'] ?? 'draft').toString();
                  final canServe = status != 'served';
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _ticketStatusColor(status).withOpacity(0.12),
                                foregroundColor: _ticketStatusColor(status),
                                child: Text('$qty'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (route.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        route,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                    if (note.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AvooColors.navy),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _ticketStatusLabel(status),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _ticketStatusColor(status),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (canServe)
                                    TextButton(
                                      onPressed: () => onMarkServed(doc.reference),
                                      child: const Text('Marquer servi'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          color: AvooColors.bone,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: busy ? null : onSend,
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onRequestBill,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Addition'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onClose,
                icon: const Icon(Icons.lock),
                label: const Text('Clôturer'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _ticketStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'open':
    case 'draft':
      return 'Ouvert';
    case 'sent':
      return 'Envoyé';
    case 'preparing':
    case 'in_progress':
      return 'En préparation';
    case 'ready':
      return 'Prêt';
    case 'served':
      return 'Servi';
    case 'payment_requested':
    case 'payment':
      return 'Addition demandée';
    case 'closed':
      return 'Clôturé';
    default:
      return status;
  }
}

Color _ticketStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
    case 'draft':
      return AvooColors.orange;
    case 'sent':
      return const Color(0xFF1976D2);
    case 'ready':
      return AvooColors.green;
    case 'payment_requested':
    case 'payment':
      return const Color(0xFF7B1FA2);
    case 'closed':
      return AvooColors.ink;
    default:
      return AvooColors.ink;
  }
}
