/// Material 3 theme configuration for Sonora.
library;

import 'package:flutter/material.dart';

import 'typography.dart';

/// Default seed color for Sonora when dynamic colors are unavailable.
const Color kDefaultSeedColor = Color(0xFF6750A4);

/// OLED-optimized pure black color.
const Color kOledBlack = Color(0xFF000000);

/// Theme mode options including OLED black.
enum SonoraThemeMode { system, light, dark, oled }

/// Creates a Sonora [ThemeData] for the given brightness and optional
/// dynamic [ColorScheme].
///
/// If [dynamicScheme] is provided (from the platform), it is used directly.
/// Otherwise, a scheme is generated from [seedColor].
ThemeData createSonoraTheme({
  required Brightness brightness,
  ColorScheme? dynamicScheme,
  Color seedColor = kDefaultSeedColor,
  bool oled = false,
}) {
  final colorScheme =
      dynamicScheme ??
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

  // For OLED mode, override surface colors to pure black
  final effectiveScheme = oled
      ? colorScheme.copyWith(
          surface: kOledBlack,
          onSurface: Colors.white,
          surfaceContainerLowest: kOledBlack,
          surfaceContainerLow: const Color(0xFF0D0D0D),
          surfaceContainer: const Color(0xFF1A1A1A),
          surfaceContainerHigh: const Color(0xFF242424),
          surfaceContainerHighest: const Color(0xFF2E2E2E),
        )
      : colorScheme;

  final textTheme = createTextTheme(
    brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: effectiveScheme,
    textTheme: textTheme,
    brightness: brightness,

    // App bar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: effectiveScheme.surface,
      foregroundColor: effectiveScheme.onSurface,
      surfaceTintColor: effectiveScheme.surfaceTint,
    ),

    // Navigation bar (bottom)
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: effectiveScheme.surfaceContainer,
      indicatorColor: effectiveScheme.secondaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(color: effectiveScheme.onSurface),
      ),
    ),

    // Navigation rail (desktop/tablet)
    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: effectiveScheme.surfaceContainerLow,
      indicatorColor: effectiveScheme.secondaryContainer,
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: effectiveScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: effectiveScheme.onSurfaceVariant,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      elevation: 0,
      color: effectiveScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom sheet (for Now Playing)
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: effectiveScheme.surfaceContainerLow,
      surfaceTintColor: effectiveScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    // Sliders (for progress bar)
    sliderTheme: SliderThemeData(
      activeTrackColor: effectiveScheme.primary,
      inactiveTrackColor: effectiveScheme.surfaceContainerHighest,
      thumbColor: effectiveScheme.primary,
      overlayColor: effectiveScheme.primary.withValues(alpha: 0.12),
      trackHeight: 4,
    ),

    // Icon buttons
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: effectiveScheme.onSurface),
    ),

    // Filled buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),

    // List tiles
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Dividers
    dividerTheme: DividerThemeData(
      color: effectiveScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 0.5,
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
