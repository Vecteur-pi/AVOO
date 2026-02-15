import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class ManagerContactInput {
  const ManagerContactInput({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  final String fullName;
  final String email;
  final String phone;
}

class OwnerSetupManagerFormScreen extends StatefulWidget {
  const OwnerSetupManagerFormScreen({super.key});

  @override
  State<OwnerSetupManagerFormScreen> createState() =>
      _OwnerSetupManagerFormScreenState();
}

class _OwnerSetupManagerFormScreenState
    extends State<OwnerSetupManagerFormScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _phoneController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _emailController.removeListener(_refresh);
    _phoneController.removeListener(_refresh);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isValid {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final hasEmailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return fullName.isNotEmpty && phone.isNotEmpty && hasEmailShape;
  }

  Future<void> _submit() async {
    if (_saving || !_isValid) return;
    setState(() {
      _saving = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(
      ManagerContactInput(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFD8E4D0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AvooColors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AvooColors.green,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Nouveau gérant',
                              style: TextStyle(
                                color: AvooColors.green,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                height: 1.06,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Renseignez les informations du gérant',
                        style: TextStyle(
                          color: Color(0xFF435067),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _FieldLabel(
                  icon: Icons.person_outline_rounded,
                  label: 'Nom complet',
                ),
                const SizedBox(height: 8),
                _InputField(
                  controller: _nameController,
                  hint: 'Ex: Jean Dupont',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _FieldLabel(
                  icon: Icons.mail_outline_rounded,
                  label: 'Adresse email',
                ),
                const SizedBox(height: 8),
                _InputField(
                  controller: _emailController,
                  hint: 'Ex: jean.dupont@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _FieldLabel(
                  icon: Icons.phone_outlined,
                  label: 'Numéro de téléphone',
                ),
                const SizedBox(height: 8),
                _InputField(
                  controller: _phoneController,
                  hint: 'Ex: +33 6 12 34 56 78',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EED9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEBCF84)),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '✦ ', style: TextStyle(fontSize: 23)),
                        TextSpan(
                          text: 'Information',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text:
                              " : Un email d'invitation sera envoyé au gérant pour qu'il puisse créer son mot de passe et accéder à l'application.",
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Color(0xFF955932),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 74,
                  child: ElevatedButton(
                    onPressed: _isValid ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid
                          ? AvooColors.green
                          : const Color(0xFFCDD3E0),
                      foregroundColor: _isValid
                          ? Colors.white
                          : const Color(0xFF6A758C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isValid
                                ? "Envoyer l'invitation"
                                : 'Remplissez tous les champs',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AvooColors.green, size: 33),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF33405A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: AvooColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFA0A8B3),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.84),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 24,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AvooColors.green, width: 1.6),
        ),
      ),
    );
  }
}
