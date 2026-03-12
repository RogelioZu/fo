import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador de carga estilizado de Finding Out.
class FoLoading extends StatelessWidget {
  const FoLoading({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color ?? AppColors.black,
        ),
      ),
    );
  }
}
