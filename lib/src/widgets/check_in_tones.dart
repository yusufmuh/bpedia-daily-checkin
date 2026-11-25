import 'package:flutter/material.dart';

/// Warna turunan untuk panel check-in.
///
/// Permukaan dan teks mengikuti `ColorScheme` host; emas dan hijau berhasil
/// memakai nilai SPEC-V3 §2.1.2 per kecerahan supaya kontrasnya terjaga di
/// tema apa pun.
@immutable
final class CheckInTones {
  /// Menurunkan warna dari tema [context].
  factory CheckInTones.of(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool dark = scheme.brightness == Brightness.dark;
    Color over(Color tint, double alpha) =>
        Color.alphaBlend(tint.withValues(alpha: alpha), scheme.surface);
    return CheckInTones._(
      dark: dark,
      brand: scheme.primary,
      onBrand: scheme.onPrimary,
      brandTint: over(scheme.primary, dark ? 0.20 : 0.10),
      brandLine: over(scheme.primary, dark ? 0.42 : 0.30),
      text: scheme.onSurface,
      textMuted: scheme.onSurfaceVariant,
      surface: scheme.surface,
      muted: over(scheme.onSurface, dark ? 0.08 : 0.045),
      line: over(scheme.onSurface, dark ? 0.14 : 0.09),
      gold: const Color(0xFFF5B83D),
      goldTint: dark ? const Color(0xFF3A2C0A) : const Color(0xFFFFF4DB),
      goldLine: dark ? const Color(0xFF7A5A12) : const Color(0xFFF7D98A),
      onGoldTint: dark ? const Color(0xFFFFD98A) : const Color(0xFF8A5A00),
      success: dark ? const Color(0xFF5FD3A0) : const Color(0xFF1E7A55),
      onSuccess: dark ? const Color(0xFF0B2A1B) : Colors.white,
      successTint: dark ? const Color(0xFF12301F) : const Color(0xFFE9F7F0),
    );
  }

  const CheckInTones._({
    required this.dark,
    required this.brand,
    required this.onBrand,
    required this.brandTint,
    required this.brandLine,
    required this.text,
    required this.textMuted,
    required this.surface,
    required this.muted,
    required this.line,
    required this.gold,
    required this.goldTint,
    required this.goldLine,
    required this.onGoldTint,
    required this.success,
    required this.onSuccess,
    required this.successTint,
  });

  /// Tema gelap.
  final bool dark;

  /// Aksen merek (`ColorScheme.primary`).
  final Color brand;

  /// Teks di atas [brand].
  final Color onBrand;

  /// Latar lembut beraksen merek.
  final Color brandTint;

  /// Garis beraksen merek.
  final Color brandLine;

  /// Teks utama.
  final Color text;

  /// Teks sekunder.
  final Color textMuted;

  /// Permukaan panel.
  final Color surface;

  /// Latar ubin netral.
  final Color muted;

  /// Garis tipis netral.
  final Color line;

  /// Emas koin.
  final Color gold;

  /// Latar ubin terklaim dan spanduk hadiah.
  final Color goldTint;

  /// Garis di atas [goldTint].
  final Color goldLine;

  /// Teks di atas [goldTint].
  final Color onGoldTint;

  /// Hijau berhasil.
  final Color success;

  /// Ikon di atas [success].
  final Color onSuccess;

  /// Latar lembut berhasil.
  final Color successTint;
}

/// Matriks warna yang menurunkan kejenuhan ke [amount] (1 = asli, 0 = abu).
ColorFilter saturationFilter(double amount) {
  final double inverse = 1 - amount;
  final double r = 0.2126 * inverse;
  final double g = 0.7152 * inverse;
  final double b = 0.0722 * inverse;
  return ColorFilter.matrix(<double>[
    r + amount, g, b, 0, 0, //
    r, g + amount, b, 0, 0, //
    r, g, b + amount, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}
