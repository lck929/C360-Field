import 'package:flutter/material.dart';

abstract final class Brand {
  static const gold = Color(0xFFCCA65C);
  static const logoGold = Color(0xFFCCA85C);
  static const toastText = Color(0xFFF3EAD8);
  static const panelLabel = Color(0xFFE9DCC0);
  static const camera = Color(0xFF0D0B09);
}

class Palette {
  const Palette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.success,
    required this.warning,
    required this.panel,
    required this.panelForeground,
    required this.panelBorder,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color success;
  final Color warning;
  final Color panel;
  final Color panelForeground;
  final Color panelBorder;

  static const light = Palette(
    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF221F1C),
    card: Color(0xFFFDFDFD),
    secondary: Color(0xFFEFEDEB),
    secondaryForeground: Color(0xFF564C43),
    muted: Color(0xFFF4F2F0),
    mutedForeground: Color(0xFF88827C),
    accent: Color(0xFFF4F1EB),
    accentForeground: Color(0xFF885F2B),
    destructive: Color(0xFFDC2828),
    border: Color(0xFFE5E3E1),
    success: Color(0xFF228B49),
    warning: Color(0xFFC26C0A),
    panel: Color(0xFF0C0A09),
    panelForeground: Color(0xFFB6B0A9),
    panelBorder: Color(0xFF221F1B),
  );

  static const dark = Palette(
    background: Color(0xFF141210),
    foreground: Color(0xFFDCD9D6),
    card: Color(0xFF1C1A17),
    secondary: Color(0xFF2D2925),
    secondaryForeground: Color(0xFFD5D1CD),
    muted: Color(0xFF272420),
    mutedForeground: Color(0xFF8E857B),
    accent: Color(0xFF312A21),
    accentForeground: Color(0xFFC5A577),
    destructive: Color(0xFFBD2828),
    border: Color(0xFF322E29),
    success: Color(0xFF43B26C),
    warning: Color(0xFFEEA62B),
    panel: Color(0xFF090807),
    panelForeground: Color(0xFFA19A91),
    panelBorder: Color(0xFF1C1A17),
  );
}

extension PaletteX on BuildContext {
  Palette get palette => Theme.of(this).brightness == Brightness.dark ? Palette.dark : Palette.light;
}

TextStyle serif({double size = 28, FontWeight weight = FontWeight.w600, Color? color, double? height}) => TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Times New Roman', 'Noto Serif'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
