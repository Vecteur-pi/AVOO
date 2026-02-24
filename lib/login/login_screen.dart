import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/user_profile.dart';
import '../registration/ui/registration_flow_screen.dart';
import '../staff/ui/staff_invite_accept_screen.dart';
import '../widgets/plate_bounce_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingResetEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Hmm, cette adresse e-mail n'a pas l'air valide. Un petit oubli dans la frappe ?"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Le mot de passe doit contenir au moins 6 caractères. 🤫"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Verify they still have an active profile in Firestore
        await UserProfileService.load(user);
      }
      
      if (!mounted) return;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _mapAuthError(error),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      // Profile not found (deleted) -> log them back out instantly
      await FirebaseAuth.instance.signOut();
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            "Oups ! 🥑 Il semblerait que vous n'ayez plus accès à cet espace. Si c'est une erreur, demandez à votre gérant de vous inviter à nouveau.",
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_isLoading || _isSendingResetEmail) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adresse e-mail invalide.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail de réinitialisation envoyé. Vérifiez votre boîte e-mail.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapPasswordResetError(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’envoyer l’e-mail de réinitialisation.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
        });
      }
    }
  }

  void _goToRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationFlowScreen()));
  }

  Future<void> _openInviteAccess() async {
    final payload = await showDialog<StaffInvitePayload>(
      context: context,
      builder: (dialogContext) {
        return const _InviteAccessDialogContent();
      },
    );

    if (!mounted || payload == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffInviteAcceptScreen(payload: payload!),
      ),
    );
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return "Hmm, cette adresse e-mail n'a pas l'air valide. Un petit oubli dans la frappe ?";
      case 'user-disabled':
        return "Votre compte a été mis en pause. N'hésitez pas à nous contacter.";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Identifiants inconnus au bataillon ! 🕵️‍♂️ Vérifiez votre e-mail ou mot de passe et réessayez.";
      case 'too-many-requests':
        return "Oula, doucement ! 🥑 Trop de tentatives échouées. Respirez un coup et réessayez dans quelques minutes.";
      default:
        return "Oops, la connexion a échoué. Vérifiez vos informations et réessayez.";
    }
  }

  String _mapPasswordResetError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-not-found':
        return 'Aucun compte ne correspond à cet e-mail.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Envoi impossible. Vérifiez votre adresse e-mail.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isSendingResetEmail;

    if (isBusy) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: PlateBounceLoader(size: 140),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF2F6EE),
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                final tight = compact;
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(28, tight ? 8 : 14, 28, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LogoCentral(compact: tight),
                            SizedBox(height: tight ? 12 : 20),
                            _WelcomeHeader(compact: tight),
                            SizedBox(height: tight ? 10 : 16),
                            _SoftField(
                              label: 'Email',
                              icon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled: !isBusy,
                            ),
                            const SizedBox(height: 10),
                            _SoftField(
                              label: 'Mot de passe',
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled: !isBusy,
                              onFieldSubmitted: (_) => _handleLogin(),
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 26,
                                  color: const Color(0xFF7A7F89),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isBusy ? null : _sendPasswordResetEmail,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF146D36),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isSendingResetEmail
                                      ? 'Envoi en cours...'
                                      : 'Mot de passe oublié ?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF146D36),
                                    decoration: TextDecoration.underline,
                                    decorationThickness: 1.5,
                                    decorationColor: const Color(0xFF146D36),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: tight ? 14 : 20),
                            _PrimaryLoginButton(
                              isLoading: _isLoading,
                              enabled: !isBusy,
                              onPressed: _handleLogin,
                            ),
                            SizedBox(height: tight ? 10 : 16),
                            const _OrDivider(),
                            SizedBox(height: tight ? 10 : 14),
                            const _SocialButton(
                              label: 'Continuer avec Google',
                              icon: _GoogleGlyph(),
                            ),
                            SizedBox(height: tight ? 16 : 24),
                            Center(
                              child: TextButton(
                                onPressed: isBusy ? null : _openInviteAccess,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  "J'ai un lien/code d'invitation",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF4B5563),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(child: SizedBox(height: 16)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Pas encore de compte ? ',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF767D8B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isBusy ? null : _goToRegistration,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2B6A3D),
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "S'Inscrire",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF2B6A3D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 2.2,
                                      decorationColor: const Color(0xFF2B6A3D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: tight ? 2 : 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteAccessDialogContent extends StatefulWidget {
  const _InviteAccessDialogContent();

  @override
  State<_InviteAccessDialogContent> createState() =>
      _InviteAccessDialogContentState();
}

class _InviteAccessDialogContentState
    extends State<_InviteAccessDialogContent> {
  final _inputController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate slight loading to feel native before parsing
    await Future.delayed(const Duration(milliseconds: 300));
    
    final parsed = StaffInvitePayload.fromRawInput(text);
    
    if (!mounted) return;

    if (parsed == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lien ou code invalide. Vérifiez votre invitation.';
      });
      return;
    }

    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Rejoindre une équipe',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Field Label
            Text(
              'Invitation',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),

            // Input Field
            TextField(
              controller: _inputController,
              autofocus: true,
              maxLines: 1,
              enabled: !_isLoading,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Lien ou code',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF146D36), width: 2.0),
                ),
                errorText: _errorMessage,
                errorStyle: GoogleFonts.poppins(
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
                errorMaxLines: 2,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) => _handleJoin(),
            ),
            if (_errorMessage == null) ...[
              const SizedBox(height: 6),
              // Helper text
              Text(
                'Collez le lien reçu ou saisissez votre code d\'invitation.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF146D36),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF146D36).withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Rejoindre',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pattern2.png',
      fit: BoxFit.cover,
    );
  }
}

class _LogoCentral extends StatelessWidget {
  const _LogoCentral({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    // avoo_logo.png is wide (waiter + brand name). Match the mockup proportion.
    final double logoWidth = compact ? 170 : 200;

    return Center(
      child: Image.asset(
        'assets/images/Logo.png',
        width: logoWidth * 1.4, // Increased size to match the mockup
        fit: BoxFit.contain,
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenu!',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1F2937), // Near black
            fontSize: compact ? 28 : 30,
            fontWeight: FontWeight.w800,
            height: 1.04,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Gérez votre restaurant facilement',
          style: GoogleFonts.poppins(
            color: const Color(0xFF4B5563), // Solid dark grey
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SoftField extends StatelessWidget {
  const _SoftField({
    required this.label,
    this.icon,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFC0D5C4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33A0D2A6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        validator: validator,
        enabled: enabled,
        obscureText: obscureText,
        onFieldSubmitted: onFieldSubmitted,
        style: GoogleFonts.poppins(
          color: const Color(0xFF7A8090),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFA0A5AF),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 22, end: 14),
                  child: Icon(icon, color: const Color(0xFF19723A), size: 24),
                ),
          prefixIconConstraints: icon == null
              ? null
              : const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 54,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon == null ? 24 : 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ou',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
      ],
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D146D36),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF146D36),
          disabledBackgroundColor: const Color(0xFF146D36),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'SE CONNECTER',
                style: GoogleFonts.poppins(
                  letterSpacing: 1.4,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});

  final String label;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          side: const BorderSide(color: Color(0xFF146D36), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF323947),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if no network
          return const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4));
        },
      ),
    );
  }
}
