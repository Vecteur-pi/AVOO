import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffInvitePayload {
  const StaffInvitePayload({
    required this.restaurantId,
    required this.invitationId,
    required this.token,
    this.email,
  });

  final String restaurantId;
  final String invitationId;
  final String token;
  final String? email;

  String get invitationCode => '$restaurantId:$invitationId:$token';

  static StaffInvitePayload? fromUri(Uri uri) {
    final scheme = uri.scheme.trim().toLowerCase();
    final host = uri.host.trim().toLowerCase();
    if (scheme != 'avoo' || host != 'accept-invite') {
      return null;
    }

    final restaurantId = (uri.queryParameters['restaurantId'] ?? '').trim();
    final invitationId = (uri.queryParameters['invitationId'] ?? '').trim();
    final token = (uri.queryParameters['token'] ?? '').trim();
    final email = (uri.queryParameters['email'] ?? '').trim().toLowerCase();
    if (restaurantId.isEmpty || invitationId.isEmpty || token.isEmpty) {
      return null;
    }

    return StaffInvitePayload(
      restaurantId: restaurantId,
      invitationId: invitationId,
      token: token,
      email: email.isEmpty ? null : email,
    );
  }

  static StaffInvitePayload? fromRawInput(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return null;
    }

    final parsedUri = Uri.tryParse(raw);
    if (parsedUri != null) {
      final fromUriPayload = fromUri(parsedUri);
      if (fromUriPayload != null) {
        return fromUriPayload;
      }
    }

    final parts = raw.split(':').map((part) => part.trim()).toList();
    if (parts.length < 3) {
      return null;
    }
    final restaurantId = parts[0];
    final invitationId = parts[1];
    final token = parts.sublist(2).join(':');
    if (restaurantId.isEmpty || invitationId.isEmpty || token.isEmpty) {
      return null;
    }
    return StaffInvitePayload(
      restaurantId: restaurantId,
      invitationId: invitationId,
      token: token,
    );
  }
}

class StaffInviteAcceptScreen extends StatefulWidget {
  const StaffInviteAcceptScreen({
    super.key,
    required this.payload,
    this.fromDeepLink = false,
  });

  final StaffInvitePayload payload;
  final bool fromDeepLink;

  @override
  State<StaffInviteAcceptScreen> createState() =>
      _StaffInviteAcceptScreenState();
}

class _StaffInviteAcceptScreenState extends State<StaffInviteAcceptScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    _emailController.text = (widget.payload.email ?? currentUserEmail ?? '')
        .trim()
        .toLowerCase();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    final requestedEmail = _emailController.text.trim().toLowerCase();
    if (requestedEmail.isEmpty || !requestedEmail.contains('@')) {
      _showSnack('Adresse e-mail invalide.');
      return;
    }

    if (widget.payload.email != null &&
        requestedEmail != widget.payload.email!.toLowerCase()) {
      _showSnack('Utilisez le même email que celui qui a reçu l’invitation.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;
        if (password.length < 6) {
          throw const _InviteException(
            'Mot de passe trop court (minimum 6 caractères).',
          );
        }
        if (password != confirmPassword) {
          throw const _InviteException(
            'La confirmation du mot de passe ne correspond pas.',
          );
        }

        try {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: requestedEmail,
                password: password,
              );
          user = credential.user;
        } on FirebaseAuthException catch (error) {
          if (error.code == 'email-already-in-use') {
            throw const _InviteException(
              'Ce compte existe déjà. Connectez-vous, puis rouvrez le lien d’invitation.',
            );
          }
          throw _InviteException(_mapCreateAccountError(error.code));
        }
      }

      if (user == null) {
        throw const _InviteException(
          'Impossible de créer ou récupérer le compte utilisateur.',
        );
      }

      final signedInEmail = (user.email ?? '').trim().toLowerCase();
      if (signedInEmail != requestedEmail) {
        throw const _InviteException(
          'Compte connecté différent. Déconnectez-vous puis recommencez avec l’email invité.',
        );
      }

      final firestore = FirebaseFirestore.instance;
      final invitationRef = firestore
          .collection('restaurants')
          .doc(widget.payload.restaurantId)
          .collection('staff_invitations')
          .doc(widget.payload.invitationId);

      final invitationSnap = await invitationRef.get();
      if (!invitationSnap.exists) {
        throw const _InviteException('Invitation introuvable.');
      }

      final invitation = invitationSnap.data() ?? const <String, dynamic>{};
      final status = _readString(invitation, const ['status'], fallback: '');
      if (status.isNotEmpty && status != 'pending') {
        throw const _InviteException('Cette invitation a déjà été utilisée.');
      }

      final inviteEmail = _readString(invitation, const [
        'email_lower',
        'email',
      ], fallback: '').toLowerCase();
      if (inviteEmail.isNotEmpty && inviteEmail != signedInEmail) {
        throw const _InviteException(
          'Cette invitation ne correspond pas à cet e-mail.',
        );
      }

      final expiresAtRaw = invitation['expires_at'] ?? invitation['expiresAt'];
      if (expiresAtRaw is Timestamp &&
          expiresAtRaw.toDate().isBefore(DateTime.now())) {
        throw const _InviteException('Cette invitation a expiré.');
      }

      final storedTokenHash = _readString(invitation, const [
        'token_hash',
        'tokenHash',
      ], fallback: '');
      final incomingHash = crypto.sha256
          .convert(utf8.encode(widget.payload.token))
          .toString();
      if (storedTokenHash.isNotEmpty && storedTokenHash != incomingHash) {
        throw const _InviteException('Lien d’invitation invalide.');
      }

      final role = _readString(invitation, const ['role'], fallback: 'serveur');
      final fullName = _readString(invitation, const [
        'full_name',
        'fullName',
      ], fallback: _fallbackName(user, signedInEmail));
      final now = FieldValue.serverTimestamp();

      final userRef = firestore.collection('users').doc(user.uid);
      final memberRef = firestore
          .collection('restaurants')
          .doc(widget.payload.restaurantId)
          .collection('members')
          .doc(user.uid);
      final restaurantUserRef = firestore
          .collection('restaurants')
          .doc(widget.payload.restaurantId)
          .collection('users')
          .doc(user.uid);

      final memberData = <String, dynamic>{
        'uid': user.uid,
        'name': fullName,
        'display_name': fullName,
        'displayName': fullName,
        'email': signedInEmail,
        'email_lower': signedInEmail,
        'role': role,
        'active': true,
        'restaurant_id': widget.payload.restaurantId,
        'restaurantId': widget.payload.restaurantId,
        'invitation_id': widget.payload.invitationId,
        'invitationId': widget.payload.invitationId,
        'invitation_status': 'accepted',
        'invitationStatus': 'accepted',
        'updated_at': now,
        'updatedAt': now,
      };

      final batch = firestore.batch();
      batch.set(userRef, <String, dynamic>{
        'uid': user.uid,
        'name': fullName,
        'display_name': fullName,
        'displayName': fullName,
        'email': signedInEmail,
        'email_lower': signedInEmail,
        'role': role,
        'active': true,
        'restaurant_id': widget.payload.restaurantId,
        'restaurantId': widget.payload.restaurantId,
        'invitation_id': widget.payload.invitationId,
        'invitationId': widget.payload.invitationId,
        'updated_at': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      batch.set(memberRef, memberData, SetOptions(merge: true));
      batch.set(restaurantUserRef, memberData, SetOptions(merge: true));
      batch.update(invitationRef, <String, dynamic>{
        'status': 'accepted',
        'accepted_by': user.uid,
        'acceptedBy': user.uid,
        'accepted_at': now,
        'acceptedAt': now,
        'updated_at': now,
        'updatedAt': now,
      });
      await batch.commit();

      if (!mounted) {
        return;
      }
      
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte configuré avec succès. Veuillez vous connecter.'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on _InviteException catch (error) {
      _showSnack(error.message);
    } on FirebaseException catch (error) {
      _showSnack(_mapFirestoreError(error.code));
    } catch (_) {
      _showSnack('Échec de l’acceptation. Réessayez.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fallbackName(User user, String email) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final fromEmail = email.split('@').first.trim();
    if (fromEmail.isNotEmpty) {
      return fromEmail;
    }
    return 'Staff';
  }

  String _mapCreateAccountError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'operation-not-allowed':
        return 'Création de compte désactivée sur Firebase Auth.';
      default:
        return 'Création du compte impossible.';
    }
  }

  String _mapFirestoreError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Permission refusée. Vérifiez vos règles Firestore.';
      case 'not-found':
        return 'Invitation introuvable.';
      default:
        return 'Erreur serveur ($code).';
    }
  }

  String _readString(
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

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.fromDeepLink
        ? 'Lien détecté depuis votre téléphone.'
        : 'Collez votre lien ou code reçu par email.';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F2),
      appBar: AppBar(
        title: const Text('Accepter l’invitation'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rejoindre l’équipe',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _readOnlyTile(
                label: 'Code invitation',
                value: widget.payload.invitationCode,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email invité',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!_isSignedIn) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF52),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _isSubmitting
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
                    : Text(
                        _isSignedIn
                            ? 'Accepter l’invitation'
                            : 'Créer le compte et accepter',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteException implements Exception {
  const _InviteException(this.message);

  final String message;
}
