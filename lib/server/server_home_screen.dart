import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/user_profile.dart';
import '../theme/avoo_theme.dart';
import 'incident_report_screen.dart';
import 'table_detail_screen.dart';

class ServerHomeScreen extends StatelessWidget {
  const ServerHomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AvooColors.bone,
        appBar: AppBar(
          title: const Text('Service'),
          backgroundColor: AvooColors.bone,
          foregroundColor: AvooColors.ink,
          elevation: 0,
          actions: [
            PopupMenuButton<_ServerMenuAction>(
              onSelected: (value) {
                if (value == _ServerMenuAction.reportIncident) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IncidentReportScreen(profile: profile),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ServerMenuAction.reportIncident,
                  child: Text('Déclarer un incident'),
                ),
              ],
            ),
            IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
            ),
          ],
          bottom: const TabBar(
            labelColor: AvooColors.ink,
            indicatorColor: AvooColors.green,
            tabs: [
              Tab(text: 'Tables'),
              Tab(text: 'Tickets'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TablesTab(profile: profile),
            TicketsTab(profile: profile),
          ],
        ),
      ),
    );
  }
}

class TablesTab extends StatelessWidget {
  const TablesTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final tablesRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(profile.restaurantId)
        .collection('tables')
        .orderBy('number');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tablesRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur lors du chargement des tables.'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Aucune table trouvée.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = _tableName(doc.id, data);
            final status = (data['status'] ?? 'free').toString();
            final statusLabel = _tableStatusLabel(status);
            final statusColor = _tableStatusColor(status);

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TableDetailScreen(
                        profile: profile,
                        tableId: doc.id,
                        tableName: name,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.15),
                        foregroundColor: statusColor,
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
                            const SizedBox(height: 4),
                            Text(
                              statusLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TicketsTab extends StatelessWidget {
  const TicketsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ticketsRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(profile.restaurantId)
        .collection('tickets')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ticketsRef,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur lors du chargement des tickets.'));
        }
        final docs = (snapshot.data?.docs ?? [])
            .where((doc) => (doc.data()['closed'] ?? false) == false)
            .toList();
        docs.sort((a, b) {
          final aTime = a.data()['updated_at'] as Timestamp?;
          final bTime = b.data()['updated_at'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        if (docs.isEmpty) {
          return const Center(child: Text('Aucun ticket ouvert.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final tableName = (data['table_label'] ??
                    data['tableName'] ??
                    data['table'] ??
                    data['table_id'] ??
                    data['tableId'] ??
                    'Table')
                .toString();
            final status = (data['status'] ?? 'open').toString();
            final statusLabel = _ticketStatusLabel(status);
            final statusColor = _ticketStatusColor(status);

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final tableId = (data['table_id'] ?? data['tableId'] ?? '').toString();
                  if (tableId.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TableDetailScreen(
                        profile: profile,
                        tableId: tableId,
                        tableName: tableName,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.15),
                        foregroundColor: statusColor,
                        child: const Icon(Icons.receipt_long),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tableName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _ServerMenuAction { reportIncident }

String _tableName(String id, Map<String, dynamic> data) {
  final raw = data['label'] ?? data['name'] ?? data['number'];
  if (raw != null && raw.toString().trim().isNotEmpty) {
    return raw.toString();
  }
  return 'Table $id';
}

String _tableStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'free':
    case 'libre':
      return 'Libre';
    case 'occupied':
    case 'ouverte':
    case 'open':
      return 'En cours';
    case 'ordered':
    case 'sent':
      return 'Commande envoyée';
    case 'payment':
    case 'bill':
      return 'Addition demandée';
    case 'closed':
      return 'Clôturée';
    default:
      return status;
  }
}

Color _tableStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'free':
    case 'libre':
      return AvooColors.green;
    case 'occupied':
    case 'open':
    case 'ouverte':
      return AvooColors.orange;
    case 'ordered':
    case 'sent':
      return const Color(0xFF1976D2);
    case 'payment':
    case 'bill':
      return const Color(0xFF7B1FA2);
    case 'closed':
      return AvooColors.ink;
    default:
      return AvooColors.ink;
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
