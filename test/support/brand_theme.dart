import 'package:flutter/material.dart';

/// Host ColorScheme from SPEC-CONTRACT §3 (light) and the brand dark tokens.
ColorScheme brandColorScheme(Brightness brightness) {
  return switch (brightness) {
    Brightness.light => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFD81F57),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFDE7EC),
      onPrimaryContainer: Color(0xFF45122B),
      secondary: Color(0xFFB3164B),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFBCFDB),
      onSecondaryContainer: Color(0xFF45122B),
      tertiary: Color(0xFFF5B83D),
      onTertiary: Color(0xFF2A0A18),
      tertiaryContainer: Color(0xFFFFF4DB),
      onTertiaryContainer: Color(0xFF8A5A00),
      error: Color(0xFFC62828),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFF7F8),
      onSurface: Color(0xFF45122B),
      onSurfaceVariant: Color(0xFF6E4556),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFF7F8),
      surfaceContainer: Color(0xFFFDE7EC),
      outline: Color(0xFF9C7E8A),
      outlineVariant: Color(0xFFF3D3DD),
    ),
    Brightness.dark => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF7AA0),
      onPrimary: Color(0xFF2A0A18),
      primaryContainer: Color(0xFF3B1026),
      onPrimaryContainer: Color(0xFFFDEAF0),
      secondary: Color(0xFFF9A2C1),
      onSecondary: Color(0xFF2A0A18),
      secondaryContainer: Color(0xFF5A1A36),
      onSecondaryContainer: Color(0xFFFDEAF0),
      tertiary: Color(0xFFF5B83D),
      onTertiary: Color(0xFF2A0A18),
      tertiaryContainer: Color(0xFF3D2A05),
      onTertiaryContainer: Color(0xFFF5C96B),
      error: Color(0xFFFF8A80),
      onError: Color(0xFF2A0A18),
      surface: Color(0xFF2A0A18),
      onSurface: Color(0xFFFDEAF0),
      onSurfaceVariant: Color(0xFFE7C9D4),
      surfaceContainerLowest: Color(0xFF3B1026),
      surfaceContainerLow: Color(0xFF2A0A18),
      surfaceContainer: Color(0xFF3B1026),
      outline: Color(0xFFB89AA7),
      outlineVariant: Color(0xFF5A1A36),
    ),
  };
}

/// Wraps [child] like a host screen: brand theme, padding, and the given
/// text scale and motion preference.
Widget hostApp(
  Widget child, {
  double textScale = 1,
  bool disableAnimations = true,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(colorScheme: brandColorScheme(brightness)),
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}
