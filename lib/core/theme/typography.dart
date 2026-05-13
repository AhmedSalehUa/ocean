import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Geist + Geist Mono pairing from the prototype.
class AppType {
  AppType._();

  static TextStyle _geist(double size, FontWeight w, {Color? color, double? letterSpacing, double? height}) {
    return GoogleFonts.geist(
      fontSize: size,
      fontWeight: w,
      color: color ?? AppColors.ink,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _mono(double size, FontWeight w, {Color? color, double? letterSpacing}) {
    return GoogleFonts.geistMono(
      fontSize: size,
      fontWeight: w,
      color: color ?? AppColors.ink2,
      letterSpacing: letterSpacing,
    );
  }

  // Display
  static TextStyle h1 = _geist(30, FontWeight.w600, letterSpacing: -0.6, height: 1.08);
  static TextStyle h2 = _geist(24, FontWeight.w600, letterSpacing: -0.48, height: 1.12);
  static TextStyle h3 = _geist(20, FontWeight.w600, letterSpacing: -0.4, height: 1.2);

  // Body
  static TextStyle bodyLg = _geist(17, FontWeight.w500, letterSpacing: -0.17, height: 1.35);
  static TextStyle body = _geist(15, FontWeight.w400, letterSpacing: -0.075, height: 1.45, color: AppColors.ink);
  static TextStyle bodyMuted = _geist(13, FontWeight.w400, color: AppColors.ink2, height: 1.45);
  static TextStyle label = _geist(14, FontWeight.w500, letterSpacing: -0.07, height: 1.3);
  static TextStyle caption = _geist(12, FontWeight.w400, color: AppColors.muted, height: 1.35);

  // Mono — used for eyebrows, status pills, file metadata, GPS readouts
  static TextStyle eyebrow = _mono(11, FontWeight.w400,
      color: AppColors.muted, letterSpacing: 1.32);
  static TextStyle mono10 = _mono(10, FontWeight.w400, color: AppColors.muted);
  static TextStyle mono11 = _mono(11, FontWeight.w400, color: AppColors.ink2);
  static TextStyle mono12 = _mono(12, FontWeight.w500, color: AppColors.ink);

  static TextStyle button = _geist(16, FontWeight.w500, color: Colors.white, letterSpacing: -0.08);
}
