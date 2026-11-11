// lib/shared/theme.dart
//
// Shared theme, spacing, sizing, and text styles.
// Used by all pages: Search, Home, Library, Player.

import 'package:flutter/cupertino.dart';

// ===== SPACING =====

abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ===== RADII =====

abstract final class AppRadius {
  static const double s = 6;
  static const double m = 8;
  static const double l = 12;
  static const double xl = 20;
  static const double pill = 32;
}

// ===== SIZES =====

abstract final class AppSizes {
  static const double avatar = 32;
  static const double iconButton = 44;
  static const double searchBar = 46;
  static const double filterBar = 44;
  static const double chipHeight = 36;
  static const double trackRow = 64;
  static const double trackCover = 52;
  static const double skeletonCover = 56;
  static const double miniPlayer = 64;
  static const double miniCover = 44;
  static const double tabBar = 56; // tune if your CNTabBar renders taller
  static const double artistAvatar = 120;
  static const double albumCover = 140;
  static const double playlistCover = 150;
  static const double topCover = 96;
  static const double categoryCover = 72;
  static const double categoryMaxExtent = 220;
}

// ===== DURATIONS =====

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration debounce = Duration(milliseconds: 350);
  static const Duration shimmer = Duration(milliseconds: 1400);
  static const Duration toast = Duration(milliseconds: 1800);
}

// ===== PALETTE =====

@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.gradientTop,
    required this.text,
    required this.textSecondary,
    required this.surface,
    required this.glassFill,
    required this.glassBorder,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.danger,
  });

  final bool isDark;
  final Color background;
  final Color gradientTop;
  final Color text;
  final Color textSecondary;
  final Color surface;
  final Color glassFill;
  final Color glassBorder;
  final Color divider;
  final Color accent;
  final Color onAccent;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color danger;

  static const AppPalette dark = AppPalette(
    isDark: true,
    background: Color(0xFF121212),
    gradientTop: Color(0xFF1E3A2B),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    surface: Color(0xFF242424),
    glassFill: Color(0x24FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    divider: Color(0x1FFFFFFF),
    accent: Color(0xFF1DB954),
    onAccent: Color(0xFF000000),
    shimmerBase: Color(0xFF2A2A2A),
    shimmerHighlight: Color(0xFF3D3D3D),
    danger: Color(0xFFFF453A),
  );

  static const AppPalette light = AppPalette(
    isDark: false,
    background: Color(0xFFF2F2F7),
    gradientTop: Color(0xFFCDEED9),
    text: Color(0xFF000000),
    textSecondary: Color(0xFF6B6B6B),
    surface: Color(0xFFFFFFFF),
    glassFill: Color(0x14000000),
    glassBorder: Color(0x1F000000),
    divider: Color(0x1F000000),
    accent: Color(0xFF1DB954),
    onAccent: Color(0xFF000000),
    shimmerBase: Color(0xFFE0E0E0),
    shimmerHighlight: Color(0xFFF5F5F5),
    danger: Color(0xFFFF3B30),
  );

  static AppPalette of(BuildContext context) =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark ? dark : light;
}

// ===== TEXT STYLES =====

abstract final class AppTextStyles {
  static TextStyle pageTitle(AppPalette p) => TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: p.text,
  );
  static TextStyle sectionTitle(AppPalette p) =>
      TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.text);
  static TextStyle rowTitle(AppPalette p) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.text);
  static TextStyle rowSubtitle(AppPalette p) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: p.textSecondary,
  );
  static TextStyle cardTitle(AppPalette p) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text);
  static TextStyle caption(AppPalette p) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: p.textSecondary,
  );
  static TextStyle chip(AppPalette p, {required bool selected}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: selected ? p.onAccent : p.text,
  );
  static TextStyle field(AppPalette p) =>
      TextStyle(fontSize: 17, color: p.text);
  static TextStyle link(AppPalette p) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.accent);
  static const TextStyle categoryTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: CupertinoColors.white,
  );
  static TextStyle topTitle(AppPalette p) =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text);
}