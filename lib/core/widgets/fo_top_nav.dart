import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';

/// Barra de navegación superior de Finding Out.
/// Flecha de retroceso a la izquierda + ícono sparkles a la derecha.
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
        // Flecha de retroceso
        if (showBackButton)
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Icon(
              PhosphorIconsRegular.caretLeft,
              color: AppColors.black,
              size: 24,
            ),
          )
        else
          const SizedBox(width: 24),

        // Ícono sparkles
        if (showSparkle)
          const Icon(
            PhosphorIconsRegular.sparkle,
            color: AppColors.black,
            size: 24,
          )
        else
          const SizedBox(width: 24),
      ],
    );
  }
}
