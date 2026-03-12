import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Botón de ícono cuadrado de Finding Out.
/// 56×56, borde #E5E7EB, radius 16, ícono centrado.
/// Usado para el botón de Phone en la fila social.
class FoIconButton extends StatelessWidget {
  const FoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gray200),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          color: AppColors.black,
          size: 24,
        ),
      ),
    );
  }
}
