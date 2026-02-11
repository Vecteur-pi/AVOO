import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistrationField extends StatelessWidget {
  const RegistrationField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
    this.helperText,
    this.maxLines = 1,
    this.errorText,
    this.inputFormatters,
    this.fillColor,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;
  final String? helperText;
  final int maxLines;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: const Color(0xFF6AAFA5)),
        suffixIcon: suffix,
        errorText: errorText,
        filled: true,
        fillColor: fillColor ?? Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: const TextStyle(
          color: Color(0xFF7B8B88),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFB8D8D2), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF5CB3A5), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.4),
        ),
      ),
    );
  }
}
