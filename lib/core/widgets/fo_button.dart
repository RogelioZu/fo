import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

/// Botón primario reutilizable de Finding Out.
/// Pill shape (radius 100), fondo negro, altura 56.
/// Soporta estado de carga con indicador circular.
class FoButton extends StatelessWidget {
  const FoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (enabled && !isLoading) ? onPressed : null;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.gray200),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          child: _buildChild(isOutlined: true),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.black : AppColors.gray400,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
          elevation: 0,
        ),
        child: _buildChild(isOutlined: false),
      ),
    );
  }

  Widget _buildChild({required bool isOutlined}) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined ? AppColors.black : AppColors.white,
        ),
      );
    }

    return Text(
      text,
      style: AppTextStyles.buttonText.copyWith(
        color: isOutlined ? AppColors.black : AppColors.white,
      ),
    );
  }
}
