import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';
import '../widgets/avoo_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AvooBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 960) {
                  return _WideLayout(form: _buildAuthCard(context));
                }
                return _NarrowLayout(form: _buildAuthCard(context));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final translateY = (1 - value) * 24;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connexion', style: textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(
                    "Accedez a votre espace Avo'o pour piloter vos operations.",
                    style: textTheme.bodyLarge?.copyWith(
                      color: AvooColors.navy.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email professionnel',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AvooColors.green,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? true;
                          });
                        },
                      ),
                      Text('Se souvenir de moi', style: textTheme.bodyMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Mot de passe oublie ?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const _GoogleMark(),
                      label: const Text('Continuer avec Google'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AvooColors.fog,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security_outlined,
                          color: AvooColors.navy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Les droits sont attribues selon votre role (proprietaire, gerant, serveur, cuisine, bar).',
                            style: textTheme.bodySmall?.copyWith(
                              color: AvooColors.navy.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Pas encore d'acces ? Contactez le gerant pour activer votre compte.",
                    style: textTheme.bodySmall?.copyWith(
                      color: AvooColors.navy.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const _BrandHeader(), const SizedBox(height: 24), form],
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: _BrandPanel()),
          const SizedBox(width: 32),
          Align(alignment: Alignment.topCenter, child: form),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AvooPill(),
        const SizedBox(height: 18),
        Text('Bienvenue sur Avo\'o', style: textTheme.displayLarge),
        const SizedBox(height: 12),
        Text(
          'La suite temps reel pour le service, la caisse et la performance.',
          style: textTheme.bodyLarge?.copyWith(
            color: AvooColors.navy.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandHeader(),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _AvooTag(label: 'POS Serveur'),
            _AvooTag(label: 'KDS Cuisine'),
            _AvooTag(label: 'Bar'),
            _AvooTag(label: 'Stocks'),
            _AvooTag(label: 'Compta'),
            _AvooTag(label: 'QR Client'),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AvooColors.softShadow,
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acces unifie', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                "Un seul compte pour piloter la salle, la cuisine et la direction. Les permissions s'adaptent automatiquement a votre role.",
                style: textTheme.bodyMedium?.copyWith(
                  color: AvooColors.navy.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvooTag extends StatelessWidget {
  const _AvooTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AvooColors.line),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AvooColors.navy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvooPill extends StatelessWidget {
  const _AvooPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AvooColors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AvooColors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AvooColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Avo'o",
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AvooColors.green),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AvooColors.line),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AvooColors.navy,
          fontSize: 12,
        ),
      ),
    );
  }
}
