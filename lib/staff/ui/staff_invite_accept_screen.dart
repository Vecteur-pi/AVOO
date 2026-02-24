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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
      _showErrorSnack("Hmm, cette adresse e-mail n'a pas l'air valide.");
      return;
    }

    if (widget.payload.email != null &&
        requestedEmail != widget.payload.email!.toLowerCase()) {
      _showErrorSnack(
        'Utilisez le même email que celui qui a reçu l\u2019invitation.',
      );
      return;
    }

    if (!_isSignedIn) {
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      if (password.isEmpty || password.length < 6) {
        _showErrorSnack(
          'Le mot de passe doit contenir au moins 6 caractères. 🤫',
        );
        return;
      }
      if (password != confirmPassword) {
        _showErrorSnack('La confirmation du mot de passe ne correspond pas.');
        return;
      }
    }

    final wasSignedInInitially = _isSignedIn;

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final password = _passwordController.text;

        try {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: requestedEmail,
                password: password,
              );
          user = credential.user;
        } on FirebaseAuthException catch (error) {
          if (error.code == 'email-already-in-use') {
            // Auth account still exists from a previous deleted session.
            // Try to log them in with the password they provided.
            try {
              final loginCredential = await FirebaseAuth.instance
                  .signInWithEmailAndPassword(
                    email: requestedEmail,
                    password: password,
                  );
              user = loginCredential.user;
            } on FirebaseAuthException catch (loginError) {
              if (loginError.code == 'wrong-password' ||
                  loginError.code == 'invalid-credential') {
                throw const _InviteException(
                  'Ce compte existe déjà. Utilisez votre ancien mot de passe pour accepter l\u2019invitation.',
                );
              }
              throw _InviteException(_mapCreateAccountError(loginError.code));
            }
          } else {
            throw _InviteException(_mapCreateAccountError(error.code));
          }
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
          'Compte connecté différent. Déconnectez-vous puis recommencez avec l\u2019email invité.',
        );
      }

      // Force refresh the Firebase Auth ID token so Firestore sees the
      // correct email claim. Without this, a freshly created account may
      // use a cached token that hasn't propagated the email yet, causing
      // the emailMatchesCurrentUser() Firestore rule to fail.
      await user.getIdToken(true);

      final firestore = FirebaseFirestore.instance;
      final invitationRef = firestore
          .collection('restaurants')
          .doc(widget.payload.restaurantId)
          .collection('staff_invitations')
          .doc(widget.payload.invitationId);

      final DocumentSnapshot<Map<String, dynamic>> invitationSnap;
      try {
        invitationSnap = await invitationRef.get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw const _InviteException(
            'Accès refusé à cette invitation. Vérifiez que vous utilisez bien l\u2019email qui a reçu l\u2019invitation.',
          );
        }
        rethrow;
      }
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
        throw const _InviteException('Lien d\u2019invitation invalide.');
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

      // Best-effort: delete the pending stub member doc(s) left by the owner.
      // This query requires read access to `members`, which the new user may
      // not have yet (they haven't been written to Firestore). So we silently
      // ignore permission errors here — the staff list's de-duplication logic
      // will hide the stub once the active member doc exists.
      try {
        final membersRef = firestore
            .collection('restaurants')
            .doc(widget.payload.restaurantId)
            .collection('members');
        final stubDocs = await membersRef
            .where('invitation_id', isEqualTo: widget.payload.invitationId)
            .where('active', isEqualTo: false)
            .get();
        for (final stub in stubDocs.docs) {
          // Don't delete ourself if somehow keyed by uid already
          if (stub.id != user.uid) {
            batch.delete(stub.reference);
          }
        }
      } on FirebaseException catch (_) {
        // Permission denied or other Firestore error — skip cleanup silently.
      }

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
      try {
        await batch.commit();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw const _InviteException(
            'Enregistrement refusé. Les règles Firestore bloquent l\u2019écriture — vérifiez que les règles ont bien été déployées (firebase deploy --only firestore:rules).',
          );
        }
        rethrow;
      }

      if (!mounted) {
        return;
      }

      // Only sign out if the user was NOT already signed in before this flow.
      // If they were already signed in (e.g. owner testing), just go back.
      if (!wasSignedInInitially) {
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSignedInInitially
                ? 'Invitation acceptée avec succès !'
                : 'Compte configuré avec succès. Veuillez vous connecter.',
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on _InviteException catch (error) {
      if (!wasSignedInInitially && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      _showErrorSnack(error.message);
    } on FirebaseException catch (error) {
      if (!wasSignedInInitially && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      if (error.code == 'permission-denied') {
        _showErrorSnack(
          "Cette invitation a été supprimée ou n'est plus valide.",
        );
      } else {
        _showErrorSnack(_mapFirestoreError(error.code));
      }
    } catch (_) {
      if (!wasSignedInInitially && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
      _showErrorSnack('Échec de l\u2019acceptation. Réessayez.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        return 'Mot de passe trop faible (minimum 6 caractères).';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F2),
      appBar: AppBar(
        title: const Text('Accepter l\u2019invitation'),
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
                'Rejoindre l\u2019équipe',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saisissez votre email et créez un mot de passe pour rejoindre votre équipe.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction:
                    _isSignedIn ? TextInputAction.done : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email invité',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
              ),
              if (!_isSignedIn) ...[
                const SizedBox(height: 12),
                // Password field with eye toggle
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe (min. 6 caractères)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF7A7F89),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm password field with eye toggle
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        );
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF7A7F89),
                      ),
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                            ? 'Accepter l\u2019invitation'
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
}

class _InviteException implements Exception {
  const _InviteException(this.message);

  final String message;
}
