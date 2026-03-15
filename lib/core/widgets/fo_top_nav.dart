import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

/// Barra de navegación superior de Finding Out.
/// Flecha de retroceso con splash circular y feedback háptico.
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
        if (showBackButton)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                (onBack ?? () => Navigator.of(context).maybePop())();
              },
              customBorder: const CircleBorder(),
              splashColor: AppColors.gray100,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.black,
                  size: 24,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 40),

        if (showSparkle)
          const Icon(
            LucideIcons.sparkles,
            color: AppColors.black,
            size: 24,
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }
}
