import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/user_profile.dart';
import 'widgets/role_modification_bottom_sheet.dart';

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

  bool _isLockedOwnerRole(String role) {
    final normalized = role.toLowerCase().trim();
    return normalized == 'owner' ||
        normalized == 'owner_manager' ||
        normalized == 'owner-manager' ||
        normalized == 'proprietaire' ||
        normalized == 'propriétaire';
  }

  bool _isLockedOwnerMember(_TeamMember member) {
    return _isLockedOwnerRole(member.role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9FAFB,
      ), // Lighter background for premium feel
      appBar: AppBar(
        title: const Text(
          'Équipe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _membersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _EmptyState(
              title: 'Impossible de charger l\'équipe',
              subtitle: 'Vérifiez votre connexion puis réessayez.',
              icon: Icons.error_outline,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allMembers =
              snapshot.data?.docs.map(_TeamMember.fromSnapshot).toList() ??
              <_TeamMember>[];
          var members = allMembers.where((m) => m.id != profile.uid).toList();

          // 2. Filter out duplicates:
          // hide pending invite rows when a real joined member already exists
          // for the same email, even if that member is inactive.
          final joinedEmails = allMembers
              .where(
                (m) =>
                    m.email.isNotEmpty &&
                    (m.uid.isNotEmpty ||
                        m.invitationStatus.toLowerCase() == 'accepted'),
              )
              .map((m) => m.email.toLowerCase())
              .toSet();
          members = members.where((m) {
            final isPendingInvite =
                m.invitationStatus.toLowerCase() == 'pending' && m.uid.isEmpty;
            if (isPendingInvite && m.email.isNotEmpty) {
              return !joinedEmails.contains(m.email.toLowerCase());
            }
            return true;
          }).toList();

          if (members.isEmpty) {
            return _EmptyState(
              title: 'Aucun membre pour l\'instant',
              subtitle:
                  'Ajoutez votre premier membre pour commencer à gérer votre équipe.',
              icon: Icons.people_outline,
              onAddPressed: _canManageTeam
                  ? () => _openAddStaffSheet(context)
                  : null,
            );
          }

          members.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          final activeCount = members.where((m) => m.active).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Zone
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Color(0xFF146D36),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${members.length} membre${members.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$activeCount actif${activeCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section Title
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Membres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              // Member List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final canManageMember =
                        _canManageTeam && !_isLockedOwnerMember(member);
                    return _MemberTile(
                      member: member,
                      canManageTeam: canManageMember,
                      onEditRole: () => _showEditRoleDialog(context, member),
                      onToggleStatus: () =>
                          _toggleMemberStatus(context, member),
                      onDelete: () => _confirmDeleteMember(context, member),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _canManageTeam
          ? FloatingActionButton.extended(
              onPressed: () => _openAddStaffSheet(context),
              backgroundColor: const Color(0xFF146D36),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 22),
              label: const Text(
                'Ajouter un membre',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _confirmDeleteMember(
    BuildContext context,
    _TeamMember member,
  ) async {
    if (_isLockedOwnerMember(member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le compte propriétaire ne peut pas être modifié.'),
        ),
      );
      return;
    }

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
      final batch = FirebaseFirestore.instance.batch();

      // Delete the selected member document (restaurants/{id}/members/{uid})
      batch.delete(_membersRef.doc(member.id));

      // Only delete from user collections if they have fully joined (has a real uid)
      if (member.invitationStatus != 'pending' && member.uid.isNotEmpty) {
        // Delete from global users collection (users/{uid})
        batch.delete(
          FirebaseFirestore.instance.collection('users').doc(member.uid),
        );

        // Delete from restaurant users collection (restaurants/{id}/users/{uid})
        batch.delete(
          FirebaseFirestore.instance
              .collection('restaurants')
              .doc(profile.restaurantId)
              .collection('users')
              .doc(member.uid),
        );
      }

      if (member.email.isNotEmpty) {
        // Delete any related member documents with the same email (e.g., old pending invitations)
        final membersWithEmail = await _membersRef
            .where('email', isEqualTo: member.email)
            .get();
        for (final doc in membersWithEmail.docs) {
          batch.delete(doc.reference);
        }

        // Delete any related invitations in staff_invitations collection
        final invitesWithEmail = await _invitationsRef
            .where('email', isEqualTo: member.email)
            .get();
        for (final doc in invitesWithEmail.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${member.name} a été supprimé.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression.')),
      );
    }
  }

  Future<void> _toggleMemberStatus(
    BuildContext context,
    _TeamMember member,
  ) async {
    if (_isLockedOwnerMember(member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le compte propriétaire ne peut pas être modifié.'),
        ),
      );
      return;
    }

    final newState = !member.active;
    final verb = newState ? 'activé' : 'désactivé';

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update members list (use set with merge in case doc is missing fields)
      batch.set(_membersRef.doc(member.id), {
        'active': newState,
      }, SetOptions(merge: true));

      // Only update global and restaurant user docs if the user has actually joined (has a real uid)
      if (member.invitationStatus != 'pending' && member.uid.isNotEmpty) {
        // Update global user list
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(member.uid),
          {'active': newState},
          SetOptions(merge: true),
        );

        // Update restaurant user list
        batch.set(
          FirebaseFirestore.instance
              .collection('restaurants')
              .doc(profile.restaurantId)
              .collection('users')
              .doc(member.uid),
          {'active': newState},
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accès $verb pour ${member.name}.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour du statut.'),
        ),
      );
    }
  }

  Future<void> _showEditRoleDialog(
    BuildContext context,
    _TeamMember member,
  ) async {
    if (_isLockedOwnerMember(member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le compte propriétaire ne peut pas être modifié.'),
        ),
      );
      return;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return RoleModificationBottomSheet(
          memberName: member.name,
          currentRole: member.role,
          onSave: (newRole) async {
            // Re-use logic but wrapped inside the bottom sheet execution block
            final batch = FirebaseFirestore.instance.batch();

            batch.set(_membersRef.doc(member.id), {
              'role': newRole,
            }, SetOptions(merge: true));

            if (member.invitationStatus != 'pending' && member.uid.isNotEmpty) {
              batch.set(
                FirebaseFirestore.instance.collection('users').doc(member.uid),
                {'role': newRole},
                SetOptions(merge: true),
              );

              batch.set(
                FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(profile.restaurantId)
                    .collection('users')
                    .doc(member.uid),
                {'role': newRole},
                SetOptions(merge: true),
              );
            }

            await batch.commit();

            if (!sheetContext.mounted) return;
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              SnackBar(
                content: Text('Le rôle de ${member.name} a été mis à jour.'),
              ),
            );
          },
        );
      },
    );

    if (confirm != true) return;
  }

  Future<void> _openAddStaffSheet(BuildContext parentContext) async {
    final pendingInvite = await showModalBottomSheet<_PendingInvite>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        const SnackBar(content: Text('Nom et email sont obligatoires.')),
      );
      return;
    }

    setState(() => isSaving = true);

    CollectionReference<Map<String, dynamic>> membersRef = FirebaseFirestore
        .instance
        .collection('restaurants')
        .doc(widget.profile.restaurantId)
        .collection('members');

    CollectionReference<Map<String, dynamic>> invitationsRef = FirebaseFirestore
        .instance
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
          const SnackBar(content: Text('Ce membre existe déjà dans l’équipe.')),
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
          content: Text('Impossible d\'ajouter le membre. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  String _getHelperTextForRole(String role) {
    switch (role) {
      case 'serveur':
        return 'Le serveur peut prendre des commandes et gérer les tables.';
      case 'cuisine':
        return 'Accès aux écrans de préparation et de gestion des plats.';
      case 'bar':
        return 'Accès aux commandes de boissons et gestion du bar.';
      case 'caissier':
        return 'Accès à la facturation et aux encaissements.';
      case 'manager':
        return 'Accès complet incluant les rapports et la gestion de l\'équipe.';
      default:
        return 'Permissions standards.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajouter un membre',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Invitez une personne dans votre équipe et attribuez-lui un rôle.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section A - Informations
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),

          _ModernTextField(
            label: 'Nom complet',
            controller: nameController,
            hint: 'Ex. Bertrand Makaya',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          _ModernTextField(
            label: 'Email',
            controller: emailController,
            hint: 'nom@exemple.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          _ModernTextField(
            label: 'Téléphone (optionnel)',
            controller: phoneController,
            hint: '+33 6 12 34 56 78',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 24),

          // Section B - Accès / Permissions
          const Text(
            'Rôle & Permissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['serveur', 'cuisine', 'bar', 'caissier', 'manager'].map((
              roleKey,
            ) {
              final isSelected = selectedRole == roleKey;
              final displayRole =
                  roleKey[0].toUpperCase() + roleKey.substring(1);

              return ChoiceChip(
                label: Text(
                  displayRole,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF146D36)
                        : const Color(0xFF4B5563),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => selectedRole = roleKey);
                  }
                },
                backgroundColor: const Color(0xFFF3F4F6),
                selectedColor: const Color(0xFFE8F5E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF146D36).withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              );
            }).toList(),
          ),

          // Role Helper Text
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getHelperTextForRole(selectedRole),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF146D36),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF146D36).withOpacity(0.5),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Inviter le membre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF146D36), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.canManageTeam,
    required this.onEditRole,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final _TeamMember member;
  final bool canManageTeam;
  final VoidCallback onEditRole;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), // Light green circle
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: const TextStyle(
                color: Color(0xFF146D36), // Dark green text
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (member.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.phone,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoleChip(role: member.role),
                    _StatusChip(member: member),
                  ],
                ),
              ],
            ),
          ),
          // Menu
          if (canManageTeam)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF9CA3AF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
              onSelected: (action) {
                switch (action) {
                  case 'edit_role':
                    onEditRole();
                    break;
                  case 'toggle_status':
                    onToggleStatus();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit_role',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xFF4B5563),
                      ),
                      SizedBox(width: 12),
                      Text('Modifier le rôle'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        member.active
                            ? Icons.block_flipped
                            : Icons.check_circle_outline,
                        size: 20,
                        color: const Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        member.active
                            ? 'Désactiver l\'accès'
                            : 'Activer l\'accès',
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toLowerCase(), // Ensure consistent casing
        style: const TextStyle(
          color: Color(0xFF1D4ED8), // Dark blue text
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
        ? 'En attente' // Shorter text
        : (member.active ? 'Actif' : 'Inactif');

    final color = isPending
        ? const Color(0xFFB45309) // Amber text
        : (member.active ? const Color(0xFF15803D) : const Color(0xFF6B7280));
    final background = isPending
        ? const Color(0xFFFEF3C7) // Amber bg
        : (member.active ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
    this.onAddPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF146D36)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            if (onAddPressed != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onAddPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF146D36),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text(
                  'Ajouter un membre',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.invitationStatus,
  });

  final String id; // Firestore document ID in the members sub-collection
  final String uid; // Firebase Auth UID (set when user has actually joined)
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
    final uid = _readString(data, const ['uid'], fallback: '');

    return _TeamMember(
      id: doc.id,
      uid: uid,
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
