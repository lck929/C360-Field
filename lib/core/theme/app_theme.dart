import 'package:c360/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final lightTheme = _theme(Palette.light, Brightness.light);
final darkTheme = _theme(Palette.dark, Brightness.dark);

ThemeData _theme(Palette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  final scheme = ColorScheme(
    brightness: brightness,
    primary: Brand.gold,
    onPrimary: isDark ? p.background : Colors.white,
    primaryContainer: p.accent,
    onPrimaryContainer: p.accentForeground,
    secondary: p.secondary,
    onSecondary: p.secondaryForeground,
    error: p.destructive,
    onError: Colors.white,
    surface: p.card,
    onSurface: p.foreground,
    onSurfaceVariant: p.mutedForeground,
    surfaceContainerHighest: p.secondary,
    outline: p.border,
    outlineVariant: p.border,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.border));
  const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  Color selected(Set<WidgetState> s) => s.contains(WidgetState.selected) ? p.accentForeground : p.mutedForeground;

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    dividerColor: p.border,
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: serif(size: 28, height: 1.15),
          titleLarge: serif(size: 19),
          bodyLarge: const TextStyle(fontSize: 15, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          labelLarge: label,
        )
        .apply(bodyColor: p.foreground, displayColor: p.foreground),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.foreground),
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        backgroundColor: Brand.gold,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: Brand.gold.withValues(alpha: 0.5),
        disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
        textStyle: label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        backgroundColor: p.card,
        foregroundColor: p.foreground,
        side: BorderSide(color: p.border),
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.mutedForeground, minimumSize: const Size(48, 48), textStyle: label),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: TextStyle(color: p.mutedForeground),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: Brand.gold, width: 1.5)),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.border)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: selected(s)),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: selected(s))),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.secondary,
        foregroundColor: p.secondaryForeground,
        selectedBackgroundColor: p.card,
        selectedForegroundColor: p.foreground,
        side: BorderSide(color: p.secondary),
        shape: shape,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.panel,
      contentTextStyle: const TextStyle(color: Brand.toastText, fontSize: 13.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.panelBorder)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Brand.gold : null),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Brand.gold),
  );
}
