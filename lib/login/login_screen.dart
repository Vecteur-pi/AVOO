import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../registration/ui/registration_flow_screen.dart';
import '../staff/ui/staff_invite_accept_screen.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adresse e-mail invalide.')));
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mot de passe invalide.')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      // TODO: Navigate to the next screen once auth succeeds.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur inattendue est survenue.')),
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
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte ne correspond à cet e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Identifiants invalides.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Connexion impossible. Vérifiez vos informations.';
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF3F7EF),
      body: Stack(
        children: [
          const Positioned.fill(child: _LoginBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 760;
                final tight = compact;
                return Padding(
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
                            foregroundColor: const Color(0xFF54AA58),
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
                              color: const Color(0xFF54AA58),
                              decoration: TextDecoration.underline,
                              decorationThickness: 2.2,
                              decorationColor: const Color(0xFF54AA58),
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
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: isBusy ? null : _openInviteAccess,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "J'ai un lien/code d'invitation",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF4B5563),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Pas encore de compte ? ',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF767D8B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: TextButton(
                                  onPressed: isBusy ? null : _goToRegistration,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2B6A3D),
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "S'inscrire",
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: tight ? 2 : 8),
                    ],
                  ),
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
  final inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lien / code invitation'),
      content: TextField(
        controller: inputController,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText:
              'Collez le lien avoo://... ou le code restaurantId:invitationId:token',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = StaffInvitePayload.fromRawInput(
              inputController.text,
            );
            if (parsed == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien/code invalide.')),
              );
              return;
            }
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Continuer'),
        ),
      ],
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.95, -1),
          end: Alignment(1, 1),
          colors: [Color(0xFFF8FBF6), Color(0xFFF0F4EC), Color(0xFFF7F9F5)],
          stops: [0, 0.58, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1, -0.2),
                  radius: 0.95,
                  colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -132,
            bottom: 108,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                color: Color(0x1FCDE0C1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCentral extends StatelessWidget {
  const _LogoCentral({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_new.png',
          height: compact ? 62 : 76,
          width: compact ? 62 : 76,
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          "Avo'o",
          style: GoogleFonts.poppins(
            fontSize: compact ? 24 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2F6E43),
            letterSpacing: 0.1,
          ),
        ),
      ],
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
            color: const Color(0xFF146D36),
            fontSize: compact ? 28 : 30,
            fontWeight: FontWeight.w800,
            height: 1.04,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Gérez votre restaurant facilement',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6E7380),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0x12000000),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  padding: const EdgeInsetsDirectional.only(start: 20, end: 14),
                  child: Icon(icon, color: const Color(0xFF4CB860), size: 24),
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
        const Expanded(child: Divider(color: Color(0xFFE2E4E8), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'OU',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB6BAC2),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E4E8), thickness: 1)),
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
            color: const Color(0x664EB95F),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF52),
          disabledBackgroundColor: const Color(0xFF4CAF52),
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
          foregroundColor: const Color(0xFF374151),
          side: const BorderSide(color: Color(0xFFDCE0E5), width: 1.6),
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
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    void drawArc(Color color, double startDegrees, double sweepDegrees) {
      canvas.drawArc(
        rect,
        _degToRad(startDegrees),
        _degToRad(sweepDegrees),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    drawArc(const Color(0xFF4285F4), -42, 116);
    drawArc(const Color(0xFFEA4335), 74, 82);
    drawArc(const Color(0xFFFBBC05), 156, 86);
    drawArc(const Color(0xFF34A853), 242, 76);

    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.49),
      Offset(size.width * 0.88, size.height * 0.49),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
