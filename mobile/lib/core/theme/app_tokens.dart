import 'package:flutter/material.dart';

/// Shared visual values. Student body text starts at 18sp per the BRD.
abstract final class AppTokens {
  // Kebun Kata palette. Keep product naming as BacaTepat in every surface.
  static const primary = Color(0xFF1D766D);
  static const primaryDark = Color(0xFF155A53);
  static const secondary = Color(0xFF2D6694);
  static const accent = Color(0xFFF4C14F);
  static const coral = Color(0xFFE8785E);
  static const background = Color(0xFFFFF9ED);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF19364A);
  static const mutedText = Color(0xFF4B6471);
  static const outline = Color(0xFFD6E3DE);
  static const mint = Color(0xFFE7F3E8);
  static const sky = Color(0xFFE9F4FA);
  static const sunshine = Color(0xFFFFF3CF);
  static const coralSoft = Color(0xFFFCE8E3);
  static const coralDark = Color(0xFFA84534);
  static const success = primary;
  static const error = Color(0xFFB33E3E);

  static const radiusSmall = 12.0;
  static const radiusMedium = 18.0;
  static const radiusLarge = 24.0;
  static const minimumTouchTarget = 48.0;
  static const buttonHeight = 52.0;
  static const studentButtonHeight = 56.0;

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
}
