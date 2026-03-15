import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Botón de ícono cuadrado de Finding Out.
/// 56x56, borde, radius 16, splash ink effect y feedback háptico.
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
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onPressed != null
              ? () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                }
              : null,
          borderRadius: AppRadius.cardRadius,
          splashColor: AppColors.gray100,
          highlightColor: AppColors.gray50,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.gray200),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppColors.black,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
