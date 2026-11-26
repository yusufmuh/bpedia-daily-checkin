import 'package:daily_checkin/daily_checkin.dart';
import 'package:daily_checkin/src/kit/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/check_in_harness.dart';
import '../support/shot.dart';

Future<void> _claimAndCapture(
  WidgetTester tester, {
  required LocalCheckInController controller,
  required String name,
  Brightness brightness = Brightness.light,
  bool strip = true,
}) async {
  await pumpShot(tester, checkInPageApp(controller, brightness: brightness));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(find.byKey(CheckInPage.primaryButtonKey));
  if (strip) {
    await shotStrip(
      tester,
      '${name}_strip',
      frames: 12,
      step: const Duration(milliseconds: 130),
    );
  }
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleImages(tester);
  await saveShot(tester, '${name}_hasil');
  await tester.tap(find.byType(CandyButton).last);
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settleImages(tester, rounds: 3);
  await saveShot(tester, '${name}_setelah');
}

void main() {
  testWidgets('klaim biasa hari ke-12, Roda Sabtu siap', (
    WidgetTester tester,
  ) async {
    await _claimAndCapture(
      tester,
      controller: localController(streak: 11, balance: 128)..wheelReady = true,
      name: 'klaim_biasa',
    );
  });

  testWidgets('klaim bonus hari ke-7', (WidgetTester tester) async {
    await _claimAndCapture(
      tester,
      controller: localController(streak: 6),
      name: 'klaim_bonus',
    );
  });

  testWidgets('klaim hari ke-30, gelap', (WidgetTester tester) async {
    await _claimAndCapture(
      tester,
      controller: localController(streak: 29, balance: 130),
      name: 'klaim_hari30',
      brightness: Brightness.dark,
    );
  });

  testWidgets('klaim biasa, gelap', (WidgetTester tester) async {
    await _claimAndCapture(
      tester,
      controller: localController(streak: 12),
      name: 'klaim_gelap',
      brightness: Brightness.dark,
      strip: false,
    );
  });
}
