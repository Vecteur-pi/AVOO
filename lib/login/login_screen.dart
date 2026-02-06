import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = _LoginBody(
            obscurePassword: _obscurePassword,
            rememberMe: _rememberMe,
            onTogglePassword: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            onToggleRemember: (value) {
              setState(() {
                _rememberMe = value ?? true;
              });
            },
          );

          if (constraints.maxWidth >= 700) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody({
    required this.obscurePassword,
    required this.rememberMe,
    required this.onTogglePassword,
    required this.onToggleRemember,
  });

  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onToggleRemember;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = math.min(
          320.0,
          math.max(240.0, constraints.maxHeight * 0.36),
        );
        final sheetMinHeight = math.max(
          0.0,
          constraints.maxHeight - heroHeight,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: heroHeight, child: const _LeafHero()),
              Container(
                constraints: BoxConstraints(minHeight: sheetMinHeight),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displayMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Login to your account',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AvooColors.navy.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const _LeafBadge(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SoftField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      _SoftField(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: obscurePassword,
                        suffix: IconButton(
                          onPressed: onTogglePassword,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            activeColor: AvooColors.green,
                            onChanged: onToggleRemember,
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forget Password ?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AvooColors.navy.withOpacity(0.5),
                                  ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _SocialChip(icon: Icons.facebook),
                          SizedBox(width: 14),
                          _SocialChip(icon: Icons.g_mobiledata_rounded),
                          SizedBox(width: 14),
                          _SocialChip(icon: Icons.apple),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AvooColors.navy.withOpacity(0.6),
                                ),
                            children: const [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign up',
                                style: TextStyle(
                                  color: AvooColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeafHero extends StatelessWidget {
  const _LeafHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0E2418), Color(0xFF1E3E2B), Color(0xFF264A35)],
            ),
          ),
        ),
        const _LeafTexture(),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 18, left: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.75),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AvooColors.navy,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 28,
          right: 26,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AvooColors.orange.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AvooColors.orange.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LeafTexture extends StatelessWidget {
  const _LeafTexture();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _LeafBlob(
          offset: Offset(-40, -20),
          size: 220,
          color: Color(0xFF1B3A28),
        ),
        _LeafBlob(
          offset: Offset(140, -40),
          size: 260,
          color: Color(0xFF173321),
        ),
        _LeafBlob(offset: Offset(40, 40), size: 200, color: Color(0xFF21422F)),
        _LeafBlob(offset: Offset(220, 60), size: 180, color: Color(0xFF2C5A40)),
      ],
    );
  }
}

class _LeafBlob extends StatelessWidget {
  const _LeafBlob({
    required this.offset,
    required this.size,
    required this.color,
  });

  final Offset offset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size * 0.78,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(120),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeafBadge extends StatelessWidget {
  const _LeafBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AvooColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.eco, color: AvooColors.green),
    );
  }
}

class _SoftField extends StatelessWidget {
  const _SoftField({
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFE9EFE7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AvooColors.green, width: 1.3),
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AvooColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140C1827),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: AvooColors.navy),
    );
  }
}
