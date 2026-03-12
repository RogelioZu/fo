import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Barra de navegación superior de Finding Out.
/// Flecha de retroceso (lucide chevron-left) a la izquierda
/// + ícono sparkles (lucide) a la derecha.
class FoTopNav extends StatelessWidget {
  const FoTopNav({
    super.key,
    this.onBack,
    this.showBackButton = true,
    this.showSparkle = true,
  });

  final VoidCallback? onBack;
  final bool showBackButton;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flecha de retroceso — lucide: chevron-left
        if (showBackButton)
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Icon(
              LucideIcons.chevronLeft,
              color: AppColors.black,
              size: 24,
            ),
          )
        else
          const SizedBox(width: 24),

        // Ícono sparkles — lucide: sparkles
        if (showSparkle)
          const Icon(
            LucideIcons.sparkles,
            color: AppColors.black,
            size: 24,
          )
        else
          const SizedBox(width: 24),
      ],
    );
  }
}
