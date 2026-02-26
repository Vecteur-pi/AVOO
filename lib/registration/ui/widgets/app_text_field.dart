import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/avoo_theme.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.icon,
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
    this.maxLength,
    this.focusNode,
    this.errorText,
    this.inputFormatters,
    this.fillColor,
  });

  final String label;
  final IconData? icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
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
  final int? maxLength;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _isFocused = false;
  bool _isDirty = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _errorText = widget.errorText;
    
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      _errorText = widget.errorText;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (!_isFocused && _isDirty) {
      // Validate on blur
      _validate();
    }
  }

  void _onTextChanged() {
    if (!_isDirty && widget.controller.text.isNotEmpty) {
      _isDirty = true;
    }
    // Clear error immediately if user types to fix it, or let form validation handle it.
    if (_errorText != null) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      validator: (val) {
        // Run validation when form is submitted, but keep state.
        final error = widget.validator?.call(val);
        // We defer to let the on-blur logic handle most UI, but for form submission we need to return it.
        return error;
      },
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.enabled ? AvooColors.ink : AvooColors.muted,
          ),
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: widget.maxLines > 1,
        helperText: widget.helperText,
        prefixIcon: widget.icon != null
            ? Icon(
                widget.icon,
                color: _isFocused ? AvooColors.green : AvooColors.muted,
              )
            : null,
        suffixIcon: widget.suffix,
        errorText: _errorText,
        filled: true,
        fillColor: widget.fillColor ?? AvooColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: _errorText != null
              ? AvooColors.error
              : (_isFocused ? AvooColors.green : AvooColors.muted),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: _errorText != null
              ? AvooColors.error
              : (_isFocused ? AvooColors.green : AvooColors.muted),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AvooColors.line, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AvooColors.green, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AvooColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AvooColors.error, width: 2.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AvooColors.line.withOpacity(0.5), width: 1.0),
        ),
      ),
    );
  }
}
