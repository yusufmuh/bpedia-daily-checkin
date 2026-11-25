import 'dart:io';

import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';

import 'brand_theme.dart';

/// Kamis, 26 November 2026 pukul 10.00 WIB.
final DateTime fixedNow = DateTime.utc(2026, 11, 26, 3);

/// Jam tetap untuk [LocalCheckInController].
DateTime fixedClock() => fixedNow;

/// Produk hadiah hari ke-30 dari katalog demo (gambar dari `example/`).
final CheckInRewardProduct demoRewardProduct = CheckInRewardProduct(
  code: 'P39A06S01000089',
  name: 'Animate Whitening Day Cream 10 g',
  image: FileImage(File('example/assets/products/P39A06S01000089.webp')),
  price: 19900,
);

/// Pengendali lokal dengan jam tetap.
LocalCheckInController localController({
  bool signedIn = true,
  int balance = 24,
  int streak = 3,
  bool claimedToday = false,
  bool withProduct = true,
  bool? soundOn = true,
  Duration latency = Duration.zero,
}) {
  return LocalCheckInController(
    clock: fixedClock,
    signedIn: signedIn,
    balance: balance,
    streak: streak,
    claimedToday: claimedToday,
    rewardProduct: withProduct ? demoRewardProduct : null,
    soundOn: soundOn,
    latency: latency,
  );
}

/// Tema host seperti aplikasi Bpedia: Poppins dan warna brand.
ThemeData hostTheme(Brightness brightness) {
  return ThemeData(
    fontFamily: 'Poppins',
    colorScheme: brandColorScheme(brightness),
  );
}

/// Aplikasi uji yang memasang [child] dengan tema host.
Widget checkInApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: hostTheme(Brightness.light),
    darkTheme: hostTheme(Brightness.dark),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child,
      ),
    ),
  );
}

/// Halaman Check-in lengkap di atas [controller].
Widget checkInPageApp(
  CheckInController controller, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return checkInApp(
    CheckInPage(controller: controller),
    brightness: brightness,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
}
