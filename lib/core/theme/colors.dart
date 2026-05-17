import 'package:flutter/material.dart';

/// Ocean Ship · Egyptian Ports & Suez Canal palette.
///
/// Brand swatches (1–5):
///   1. Main Navy     #012169
///   2. Teal Accent   #008080
///   3. Muted Gold    #D4AF37
///   4. Sand Gray     #E0DED7
///   5. Sea Spray     #F5F7FA
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF012169);
  static const Color teal = Color(0xFF008080);
  static const Color gold = Color(0xFFD4AF37);
  static const Color sand = Color(0xFFE0DED7);
  static const Color sea = Color(0xFFF5F7FA);

  // ── Background ────────────────────────────────────────────────────────────
  static const Color bg = sea;
  static const Color bgDeep = sand;
  static const Color bgWarmHi = Color(0xFFFAFBFD);
  static const Color bgWarmLo = sand;

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);

  // ── Ink (text) ────────────────────────────────────────────────────────────
  static const Color ink = navy;
  static const Color ink2 = Color(0xFF1E3A8A);
  static const Color muted = Color(0xFF6B7280);
  static const Color muted2 = Color(0xFF9CA3AF);

  // ── Lines ─────────────────────────────────────────────────────────────────
  static const Color line = Color(0xFFD6D4CC);
  static const Color lineSoft = Color(0xFFE6E4DC);

  // ── Accent (teal) ─────────────────────────────────────────────────────────
  static const Color accent = teal;
  static const Color accentInk = Color(0xFF005F5F);
  static const Color accentSoft = Color(0xFFD6ECEC);

  // ── Warn (gold) ───────────────────────────────────────────────────────────
  static const Color warn = gold;
  static const Color warnSoft = Color(0xFFFAEFCB);
  static const Color warnInk = Color(0xFF7A6420);

  // ── Danger ────────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFB94A3D);
  static const Color dangerSoft = Color(0xFFF6E1DC);

  /// Dark camera surface (shipment + guided item capture).
  static const Color darkBg = Color(0xFF0A0E1F);
  static const Color darkSurface = Color(0xFF111733);
}
