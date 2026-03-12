import 'package:flutter/material.dart';

/// Paleta de colores de Finding Out.
/// Diseño minimalista B&W extraído de login.pen.
class AppColors {
  AppColors._();

  // ─── Primarios ───
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // ─── Grises ───
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray700 = Color(0xFF333333);

  // ─── Semánticos ───
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);

  // ─── Accent ───
  static const accent = Color(0xFFFF005D);
  static const accentBg = Color(0xFFFFF0F5);

  // ─── Otros ───
  static const inputBorder = gray200;
  static const placeholder = gray400;
  static const secondaryText = gray500;
  static const labelText = gray700;
  static const divider = gray100;
  static const scaffoldBg = white;
}
