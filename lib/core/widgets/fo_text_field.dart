import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Campo de texto reutilizable de Finding Out.
/// H: 56, borde animado al focus con sombra sutil, radius 16.
class FoTextField extends StatefulWidget {
  const FoTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final int? maxLength;

  @override
  State<FoTextField> createState() => _FoTextFieldState();
}

class _FoTextFieldState extends State<FoTextField> {
  late FocusNode _focusNode;
  bool _ownsNode = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsNode) _focusNode.dispose();
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _ownsNode = false;
      } else {
        _focusNode = FocusNode();
        _ownsNode = true;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        validator: widget.validator,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        style: AppTextStyles.inputText,
        cursorColor: AppColors.black,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.inputHint,
          counterText: '',
          filled: true,
          fillColor: AppColors.white,
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.black : AppColors.placeholder,
                  size: 20,
                )
              : null,
          suffixIcon: widget.suffixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(color: AppColors.black, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          errorStyle: AppTextStyles.small.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Input con label arriba (gap: 8px).
class FoLabeledInput extends StatelessWidget {
  const FoLabeledInput({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        FoTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: textInputAction,
          focusNode: focusNode,
        ),
      ],
    );
  }
}
