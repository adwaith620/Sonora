/// Custom typography configuration for Sonora.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Creates the Sonora text theme using Google Fonts.
///
/// Uses the default Material 3 type scale with a clean sans-serif font.
TextTheme createTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    // Display styles - rarely used, for hero sections
    displayLarge: GoogleFonts.inter(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w400),
    // Headline styles - section headers
    headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
    // Title styles - card titles, app bar
    titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    // Body styles - song titles, descriptions
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    // Label styles - buttons, chips, badges
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}
