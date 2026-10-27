import 'package:flutter/material.dart';

/// vaxihubV2's palette: white, red, black and light green - nothing else.
/// Each module group owns one accent (see app_modules.dart): red = Sales &
/// billing and Reports (and the app chrome - the vaxiCSR brand red), light
/// green = Clinics & customers (and "done/paid" states), black = Field
/// operations. Pages and cards are white.
class AppPalette {
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF9CCC65);
  static const black = Color(0xFF161616);

  /// Light green is too pale for text on white - this deeper shade of the
  /// same green is used wherever green has to be read (labels, figures).
  static const greenText = Color(0xFF4E8A1E);

  /// Softer red for a second chart series next to the main red.
  static const redSoft = Color(0xFFEF9A9A);

  static const heroGradient = LinearGradient(
    colors: [black, Color(0xFF3A0D0D), red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft tint of an accent for icon wells/pills, readable in both themes.
  static Color tint(Color accent, Brightness brightness) =>
      accent.withValues(alpha: brightness == Brightness.dark ? 0.24 : (_isLight(accent) ? 0.28 : 0.10));

  /// The accent as text/icon colour on its own tint: light green darkens to
  /// [greenText] on white, black turns near-white on dark backgrounds.
  static Color onTint(Color accent, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return _isVeryDark(accent) ? const Color(0xFFEDEDED) : Color.lerp(accent, Colors.white, 0.3)!;
    }
    return _isLight(accent) ? greenText : accent;
  }

  /// Gradient for coloured headers/tiles that carry white text: light green
  /// is deepened so white stays readable; black gets a subtle charcoal lift.
  static LinearGradient accentGradient(Color accent) {
    final List<Color> colors;
    if (_isVeryDark(accent)) {
      colors = [const Color(0xFF2E2E2E), accent];
    } else if (_isLight(accent)) {
      colors = [Color.lerp(accent, greenText, 0.55)!, greenText];
    } else {
      colors = [accent, Color.lerp(accent, black, 0.35)!];
    }
    return LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  static bool _isLight(Color c) => c.computeLuminance() > 0.35;
  static bool _isVeryDark(Color c) => c.computeLuminance() < 0.02;
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppPalette.red,
    brightness: brightness,
  ).copyWith(
    primary: isDark ? const Color(0xFFEF5350) : AppPalette.red,
    onPrimary: Colors.white,
    secondary: isDark ? AppPalette.green : AppPalette.greenText,
    tertiary: isDark ? const Color(0xFFEDEDED) : AppPalette.black,
    surface: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF6F6F6),
    surfaceContainer: isDark ? const Color(0xFF1A1A1A) : Colors.white,
    surfaceContainerHigh: isDark ? const Color(0xFF232323) : const Color(0xFFF0F0F0),
    surfaceContainerHighest: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8),
    onSurface: isDark ? const Color(0xFFF2F2F2) : AppPalette.black,
    onSurfaceVariant: isDark ? const Color(0xFFB5B5B5) : const Color(0xFF5C5C5C),
    outline: isDark ? const Color(0xFF7A7A7A) : const Color(0xFF8A8A8A),
    outlineVariant: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD9D9D9),
    error: AppPalette.red,
  );

  // Plus Jakarta Sans, bundled as a local asset (assets/fonts) rather than
  // fetched at runtime via google_fonts - that package's runtime fetch never
  // completed under this project's CanvasKit web debug workflow, so screens
  // silently fell back to the system font.
  final baseTextTheme = (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
      .apply(fontFamily: 'PlusJakartaSans');

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    // Tighter default spacing for list tiles, buttons and fields on phones.
    visualDensity: VisualDensity.compact,
    textTheme: baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ).copyWith(color: scheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 60,
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppPalette.tint(AppPalette.red, brightness),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11.5,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    // White cards on a cool grey page, with a hairline border instead of a
    // shadow - keeps lists light while the coloured accents carry the design.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.45)),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: AppPalette.tint(AppPalette.red, brightness),
      labelStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ).copyWith(color: scheme.onSurfaceVariant),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.red,
      foregroundColor: Colors.white,
      elevation: 2,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppPalette.black,
      contentTextStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 18,
    ),
    listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
  );
}
