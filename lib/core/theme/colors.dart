import 'package:flutter/material.dart';

/// Trail palette — ported verbatim from the Claude Design prototype.
/// oklch values from the original CSS were converted to sRGB once;
/// the hex values below are the canonical reference for the app.
class AppColors {
  AppColors._();

  // Background
  static const Color bg = Color(0xFFF4F2EC);
  static const Color bgDeep = Color(0xFFECE9E0);
  static const Color bgWarmHi = Color(0xFFFBFAF5);
  static const Color bgWarmLo = Color(0xFFEAE6D9);

  // Surface
  static const Color surface = Color(0xFFFFFFFF);

  // Ink (text)
  static const Color ink = Color(0xFF16170F);
  static const Color ink2 = Color(0xFF3A3B33);
  static const Color muted = Color(0xFF7A7B6F);
  static const Color muted2 = Color(0xFFA6A79A);

  // Lines
  static const Color line = Color(0xFFE4E1D5);
  static const Color lineSoft = Color(0xFFEFEDE3);

  // Accent (signed-off green, oklch(0.52 0.13 152))
  static const Color accent = Color(0xFF3E7A57);
  static const Color accentInk = Color(0xFF295240);
  static const Color accentSoft = Color(0xFFE0EDDE);

  // Warn (amber, oklch(0.65 0.16 65))
  static const Color warn = Color(0xFFC78A35);
  static const Color warnSoft = Color(0xFFF7EEDC);
  static const Color warnInk = Color(0xFF8A5C20);

  // Danger (red, oklch(0.55 0.18 25))
  static const Color danger = Color(0xFFB94A3D);
  static const Color dangerSoft = Color(0xFFF6E1DC);

  /// Dark camera surface (used by shipment + item-loop capture screens).
  static const Color darkBg = Color(0xFF111210);
  static const Color darkSurface = Color(0xFF1B1C18);
}
