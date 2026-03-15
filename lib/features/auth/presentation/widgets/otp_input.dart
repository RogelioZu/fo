import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Widget de input OTP de 6 dígitos para Finding Out.
/// Cada dígito tiene su propio campo con auto-avance de focus,
/// sombra al focus y animación de relleno.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    this.length = 6,
  });

  final ValueChanged<String> onCompleted;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      HapticFeedback.selectionClick();
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final code = _controllers.map((c) => c.text).join();
        if (code.length == widget.length) {
          HapticFeedback.mediumImpact();
          widget.onCompleted(code);
        }
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasFill = _controllers[index].text.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 48,
          height: 56,
          margin: EdgeInsets.only(
            right: index < widget.length - 1 ? 10 : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            color: hasFill ? AppColors.gray50 : AppColors.white,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: AppTextStyles.heading2.copyWith(fontSize: 24),
            cursorColor: AppColors.black,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardRadius,
                borderSide: BorderSide(
                  color: hasFill ? AppColors.black : AppColors.inputBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardRadius,
                borderSide:
                    const BorderSide(color: AppColors.black, width: 1.5),
              ),
            ),
            onChanged: (value) => _onChanged(value, index),
          ),
        );
      }),
    );
  }
}
