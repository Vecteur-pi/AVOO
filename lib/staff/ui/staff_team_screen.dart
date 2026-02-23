import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/user_profile.dart';

class StaffTeamScreen extends StatelessWidget {
  const StaffTeamScreen({super.key, required this.profile});

  final UserProfile profile;

  CollectionReference<Map<String, dynamic>> get _membersRef {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(profile.restaurantId)
        .collection('members');
  }

  CollectionReference<Map<String, dynamic>> get _invitationsRef {
    return FirebaseFirestore.instance
        .collection('restaurants')
        .doc(profile.restaurantId)
        .collection('staff_invitations');
  }

  bool get _canManageTeam => UserProfileService.isOwnerRole(profile.role);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F2),
      appBar: AppBar(
        title: const Text('Staff / Équipe'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          if (_canManageTeam)
            IconButton(
              tooltip: 'Ajouter un staff',
              onPressed: () => _openAddStaffSheet(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _membersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _EmptyState(
              title: 'Impossible de charger l’équipe',
              subtitle: 'Vérifiez votre connexion puis réessayez.',
              icon: Icons.error_outline,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var members =
              snapshot.data?.docs.map(_TeamMember.fromSnapshot).toList() ??
              <_TeamMember>[];

          // 1. Filter out the current owner
          members = members.where((m) => m.id != profile.uid).toList();

          // 2. Filter out duplicates (hide pending if an active member exists with same email)
          final activeEmails = members
              .where((m) => m.active && m.email.isNotEmpty)
              .map((m) => m.email.toLowerCase())
              .toSet();
          members = members.where((m) {
            if (!m.active && m.email.isNotEmpty) {
              return !activeEmails.contains(m.email.toLowerCase());
            }
            return true;
          }).toList();

          members.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          if (members.isEmpty) {
            return _EmptyState(
              title: 'Aucun staff pour le moment',
              subtitle: _canManageTeam
                  ? 'Ajoutez un membre via le bouton +'
                  : 'Demandez à votre manager de vous ajouter.',
              icon: Icons.groups_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = members[index];
              return _MemberTile(
                member: member,
                canManageTeam: _canManageTeam,
                onDelete: () => _confirmDeleteMember(context, member),
              );
            },
          );
        },
      ),
      floatingActionButton: _canManageTeam
          ? FloatingActionButton.extended(
              onPressed: () => _openAddStaffSheet(context),
              backgroundColor: const Color(0xFF4CAF52),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Ajouter un staff'),
            )
          : null,
    );
  }

  Future<void> _confirmDeleteMember(
    BuildContext context,
    _TeamMember member,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le staff'),
          content: Text(
            'Voulez-vous vraiment supprimer ${member.name} de l\'équipe ? '
            'Cette action révoquera son accès immédiatement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _membersRef.doc(member.id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} a été supprimé.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression.')),
      );
    }
  }

  Future<void> _openAddStaffSheet(BuildContext parentContext) async {
    final pendingInvite = await showModalBottomSheet<_PendingInvite>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return _AddStaffSheetContent(
          profile: profile,
          generateInviteToken: _generateInviteToken,
          hashInviteToken: _hashInviteToken,
        );
      },
    );

    if (pendingInvite == null || !parentContext.mounted) return;

    // Let the bottom-sheet route fully settle before switching apps.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!parentContext.mounted) return;

    final opened = await _openInviteEmail(
      recipientEmail: pendingInvite.recipientEmail,
      staffName: pendingInvite.staffName,
      role: pendingInvite.role,
      invitationCode:
          '${profile.restaurantId}:${pendingInvite.invitationId}:${pendingInvite.token}',
    );

    if (!parentContext.mounted) return;

    if (opened) {
      ScaffoldMessenger.maybeOf(parentContext)?.showSnackBar(
        const SnackBar(
          content: Text('Email préparé. Envoyez-le puis revenez dans Avo\'o.'),
        ),
      );
      return;
    }

    await _showManualShareDialog(
      parentContext,
      recipientEmail: pendingInvite.recipientEmail,
      invitationCode:
          '${profile.restaurantId}:${pendingInvite.invitationId}:${pendingInvite.token}',
    );
  }

  String _generateInviteToken() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _hashInviteToken(String token) {
    return crypto.sha256.convert(utf8.encode(token)).toString();
  }

  Future<bool> _openInviteEmail({
    required String recipientEmail,
    required String staffName,
    required String role,
    required String invitationCode,
  }) async {
    final subject = "Invitation Avo'o - Accès staff";
    final body =
        '''
Bonjour $staffName,

Vous avez été invité(e) à rejoindre l'équipe du restaurant sur Avo'o.

Rôle: $role

Code d'invitation:
$invitationCode

Ouvrez l'application Avo'o puis utilisez:
"J'ai un lien/code d'invitation"
et collez ce code.

Ce lien expire dans 72 heures.
''';

    final mailtoUri = Uri(
      scheme: 'mailto',
      path: recipientEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _showManualShareDialog(
    BuildContext context, {
    required String recipientEmail,
    required String invitationCode,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invitation créée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Envoi automatique indisponible pour: $recipientEmail'),
              const SizedBox(height: 12),
              const Text(
                'Copiez et envoyez ce code:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(invitationCode),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invitationCode));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Code copié.')));
              },
              child: const Text('Copier le code'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}

class _AddStaffSheetContent extends StatefulWidget {
  const _AddStaffSheetContent({
    required this.profile,
    required this.generateInviteToken,
    required this.hashInviteToken,
  });

  final UserProfile profile;
  final String Function() generateInviteToken;
  final String Function(String) hashInviteToken;

  @override
  State<_AddStaffSheetContent> createState() => _AddStaffSheetContentState();
}

class _AddStaffSheetContentState extends State<_AddStaffSheetContent> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  var selectedRole = 'serveur';
  var isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (isSaving) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom et email sont obligatoires.'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    
    CollectionReference<Map<String, dynamic>> membersRef =
        FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.profile.restaurantId)
            .collection('members');

    CollectionReference<Map<String, dynamic>> invitationsRef =
        FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.profile.restaurantId)
            .collection('staff_invitations');

    try {
      final existingByEmail = await membersRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existingByEmail.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce membre existe déjà dans l’équipe.'),
          ),
        );
        return;
      }

      final pendingInvitation = await invitationsRef
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (pendingInvitation.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Une invitation en attente existe déjà pour cet email.',
            ),
          ),
        );
        return;
      }

      final inviteToken = widget.generateInviteToken();
      final inviteTokenHash = widget.hashInviteToken(inviteToken);
      final invitationRef = invitationsRef.doc();
      final expiresAt = Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 72)),
      );

      await invitationRef.set({
        'id': invitationRef.id,
        'restaurant_id': widget.profile.restaurantId,
        'restaurantId': widget.profile.restaurantId,
        'email': email,
        'email_lower': email,
        'full_name': name,
        'fullName': name,
        'phone': phone,
        'role': selectedRole,
        'status': 'pending',
        'token_hash': inviteTokenHash,
        'tokenHash': inviteTokenHash,
        'created_by': widget.profile.uid,
        'createdBy': widget.profile.uid,
        'created_by_name': widget.profile.name,
        'createdByName': widget.profile.name,
        'expires_at': expiresAt,
        'expiresAt': expiresAt,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final docRef = membersRef.doc();
      await docRef.set({
        'uid': '',
        'display_name': name,
        'displayName': name,
        'name': name,
        'email': email,
        'phone': phone,
        'role': selectedRole,
        'active': false,
        'invitation_id': invitationRef.id,
        'invitationId': invitationRef.id,
        'invitation_email': email,
        'invitationEmail': email,
        'invitation_status': 'pending',
        'invitationStatus': 'pending',
        'restaurant_id': widget.profile.restaurantId,
        'restaurantId': widget.profile.restaurantId,
        'created_by': widget.profile.uid,
        'createdBy': widget.profile.uid,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      Navigator.of(context).pop(
        _PendingInvite(
          recipientEmail: email,
          staffName: name,
          role: selectedRole,
          invitationId: invitationRef.id,
          token: inviteToken,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajout impossible. Réessayez.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajouter un staff',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Téléphone (optionnel)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Rôle',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'serveur',
                child: Text('Serveur'),
              ),
              DropdownMenuItem(
                value: 'cuisine',
                child: Text('Cuisine'),
              ),
              DropdownMenuItem(value: 'bar', child: Text('Bar')),
              DropdownMenuItem(
                value: 'caissier',
                child: Text('Caissier'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedRole = value);
            },
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF52),
              foregroundColor: Colors.white,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.canManageTeam,
    required this.onDelete,
  });

  final _TeamMember member;
  final bool canManageTeam;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFECF5E8),
          foregroundColor: const Color(0xFF2F6F42),
          child: Text(member.initials),
        ),
        title: Text(
          member.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (member.email.isNotEmpty)
                Text(
                  member.email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              if (member.phone.isNotEmpty)
                Text(
                  member.phone,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _RoleChip(role: member.role),
                  const SizedBox(width: 8),
                  _StatusChip(member: member),
                ],
              ),
            ],
          ),
        ),
        trailing: canManageTeam
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                color: Colors.red.shade400,
                onPressed: onDelete,
                tooltip: 'Supprimer',
              )
            : null,
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFF22438E),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    final isPending = member.invitationStatus == 'pending';
    final label = isPending
        ? 'Invitation en attente'
        : (member.active ? 'Actif' : 'Inactif');
    final color = isPending
        ? const Color(0xFFA16207)
        : (member.active ? const Color(0xFF166534) : const Color(0xFF9CA3AF));
    final background = isPending
        ? const Color(0xFFFEF3C7)
        : (member.active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.invitationStatus,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool active;
  final String invitationStatus;

  String get initials {
    final parts = name
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    String firstLetter(String value) =>
        value.isEmpty ? '?' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return firstLetter(parts.first);
    return '${firstLetter(parts.first)}${firstLetter(parts.last)}';
  }

  factory _TeamMember.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = _readString(data, const [
      'display_name',
      'displayName',
      'name',
      'fullName',
    ], fallback: 'Staff');
    final role = _readString(data, const ['role'], fallback: 'staff');
    final email = _readString(data, const ['email'], fallback: '');
    final phone = _readString(data, const ['phone'], fallback: '');
    final invitationStatus = _readString(data, const [
      'invitation_status',
      'invitationStatus',
    ], fallback: '');
    final active = data['active'] == true;

    return _TeamMember(
      id: doc.id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      active: active,
      invitationStatus: invitationStatus,
    );
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }
}

class _PendingInvite {
  const _PendingInvite({
    required this.recipientEmail,
    required this.staffName,
    required this.role,
    required this.invitationId,
    required this.token,
  });

  final String recipientEmail;
  final String staffName;
  final String role;
  final String invitationId;
  final String token;
}
