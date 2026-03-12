import 'package:flutter/material.dart';

/// Tokens de border‑radius de Finding Out.
/// Valores extraídos de login.pen.
class AppRadius {
  AppRadius._();

  // ─── Valores raw ───

  /// 16px — Inputs, social buttons, code boxes
  static const double card = 16;

  /// 28px — GPS button, interest chips
  static const double chip = 28;

  /// 80px — Onboarding icon circles
  static const double circle = 80;

  /// 90px — Avatar circle (setup photo)
  static const double avatar = 90;

  /// 100px — Botones primarios (pill shape)
  static const double pill = 100;

  // ─── BorderRadius helpers ───

  static final cardRadius = BorderRadius.circular(card);
  static final chipRadius = BorderRadius.circular(chip);
  static final circleRadius = BorderRadius.circular(circle);
  static final avatarRadius = BorderRadius.circular(avatar);
  static final pillRadius = BorderRadius.circular(pill);
}
