import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/check_in_harness.dart';
import '../support/shot.dart';

const Size _long = Size(390, 1240);

void main() {
  for (final Brightness brightness in Brightness.values) {
    final String mode = brightness == Brightness.light ? 'terang' : 'gelap';

    testWidgets('halaman siap klaim, layar ponsel ($mode)', (
      WidgetTester tester,
    ) async {
      await shot(
        tester,
        checkInPageApp(localController(), brightness: brightness),
        name: 'halaman_siap_$mode',
      );
    });

    testWidgets('halaman siap klaim, panjang ($mode)', (
      WidgetTester tester,
    ) async {
      await shot(
        tester,
        checkInPageApp(localController(), brightness: brightness),
        name: 'halaman_siap_panjang_$mode',
        size: _long,
      );
    });

    testWidgets('sudah klaim hari ke-11 ($mode)', (WidgetTester tester) async {
      await shot(
        tester,
        checkInPageApp(
          localController(streak: 11, claimedToday: true, balance: 58),
          brightness: brightness,
        ),
        name: 'halaman_sudah_panjang_$mode',
        size: _long,
      );
    });

    testWidgets('hari bonus ke-7 siap ($mode)', (WidgetTester tester) async {
      await shot(
        tester,
        checkInPageApp(localController(streak: 6), brightness: brightness),
        name: 'halaman_bonus_$mode',
      );
    });

    testWidgets('hari ke-30 siap ($mode)', (WidgetTester tester) async {
      await shot(
        tester,
        checkInPageApp(
          localController(streak: 29, balance: 130),
          brightness: brightness,
        ),
        name: 'halaman_hari30_panjang_$mode',
        size: _long,
      );
    });

    testWidgets('tamu ($mode)', (WidgetTester tester) async {
      await shot(
        tester,
        checkInPageApp(
          localController(signedIn: false),
          brightness: brightness,
        ),
        name: 'halaman_tamu_$mode',
      );
    });
  }

  testWidgets('teks 200% di lebar 360', (WidgetTester tester) async {
    await shot(
      tester,
      checkInPageApp(localController(), textScale: 2),
      name: 'halaman_teks200',
      size: const Size(360, 2600),
    );
  });

  testWidgets('tanpa produk host', (WidgetTester tester) async {
    await shot(
      tester,
      checkInPageApp(localController(withProduct: false, streak: 20)),
      name: 'halaman_tanpa_produk',
      size: _long,
    );
  });
}
