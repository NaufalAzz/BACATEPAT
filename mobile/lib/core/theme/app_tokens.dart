import 'package:flutter/material.dart';

/// Shared visual values. Student body text starts at 18sp per the BRD.
abstract final class AppTokens {
  // BacaTepat palette: teal primary, slate text, warm cream canvases.
  static const primary = Color(0xFF1C6E60);
  static const primaryDark = Color(0xFF16564B);
  static const primaryLight = Color(0xFF2E8C7B);
  static const secondary = Color(0xFF2E5F7A);
  static const accent = Color(0xFFF1C04C);
  static const coral = Color(0xFFD8674A);
  static const coralLight = Color(0xFFF6D9D1);
  static const background = Color(0xFFFFF9EF);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C3A44);
  static const mutedText = Color(0xFF6E7F80);
  static const outline = Color(0xFFE3E8E5);
  static const mint = Color(0xFFE8F1E9);
  static const sky = Color(0xFFE7F0F5);
  static const sunshine = Color(0xFFFBF2D4);
  static const coralSoft = Color(0xFFFBEAE4);
  static const coralDark = Color(0xFFAE4B38);
  static const success = primary;
  static const error = Color(0xFFC0392B);
  static const warning = Color(0xFFC77F1E);

  // Spacing scale (4pt base)
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space10 = 10.0;
  static const space12 = 12.0;
  static const space14 = 14.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const space28 = 28.0;
  static const space32 = 32.0;

  // Border radius
  static const radiusSmall = 8.0;
  static const radiusMedium = 10.0;
  static const radiusLarge = 12.0;
  static const radiusXLarge = 16.0;
  static const radiusRound = 999.0;

  // Touch targets
  static const minimumTouchTarget = 48.0;
  static const buttonHeight = 48.0;
  static const studentButtonHeight = 52.0;

  // Elevation
  static const elevationCard = 0.0;
  static const elevationRaised = 0.0;
  static const elevationModal = 8.0;
  static const elevationNavBar = 8.0;

  // Animation
  static const durationFast = Duration(milliseconds: 150);

  static const cardShadow = [
    BoxShadow(color: Color(0x0A1C3A44), blurRadius: 6, offset: Offset(0, 2)),
  ];
}
