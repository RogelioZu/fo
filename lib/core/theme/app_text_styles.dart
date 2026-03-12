import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Escala tipográfica de Finding Out.
/// Fuente: Inter via Google Fonts. Extraído de login.pen.
class AppTextStyles {
  AppTextStyles._();

  // ─── Títulos ───

  /// 32px / ExtraBold (800) — Títulos principales de screen
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    height: 1.1,
  );

  /// 28px / Black (900) — Títulos de setup screens
  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.black,
    height: 1.1,
  );

  /// 24px / ExtraBold (800) — Subtítulos (splash)
  static TextStyle heading3 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
  );

  // ─── Body ───

  /// 16px / SemiBold (600) — Texto de botones, social text
  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  /// 16px / Regular (400) — Descripciones
  static TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  // ─── Labels & Links ───

  /// 14px / SemiBold (600) — Labels de inputs
  static TextStyle label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.labelText,
  );

  /// 14px / Medium (500) — Links, steps, resend timer
  static TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  /// 14px / Regular (400) — Subtextos
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  // ─── Small ───

  /// 13px / Medium (500) — Counter (interests), validación
  static TextStyle small = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  /// 16px / Regular (400) — Input hint/placeholder
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.placeholder,
  );

  /// 16px / Regular (400) — Input text
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );
}
