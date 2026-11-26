import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/check_in_harness.dart';
import 'support/shot.dart';

Future<void> _pumpFor(WidgetTester tester, int milliseconds) async {
  for (int t = 0; t < milliseconds; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _open(
  WidgetTester tester,
  CheckInController controller, {
  bool disableAnimations = true,
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    checkInPageApp(
      controller,
      disableAnimations: disableAnimations,
      textScale: textScale,
      brightness: brightness,
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Finder get _primary => find.byKey(CheckInPage.primaryButtonKey);

Future<void> _claim(WidgetTester tester) async {
  await tester.tap(_primary);
  await _pumpFor(tester, 2500);
}

void main() {
  group('CheckInPage tamu', () {
    testWidgets('halaman tetap tampil, aksi utama "Masuk untuk check-in"', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController(signedIn: false);
      await _open(tester, c);
      expect(find.text('Check-in Harian'), findsWidgets);
      expect(find.text('Selesai 30 hari!'), findsOneWidget);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Masuk untuk check-in'), findsOneWidget);
      await tester.tap(_primary);
      expect(c.actions, contains('openLogin'));
    });

    testWidgets('chip saldo mengajak masuk', (WidgetTester tester) async {
      final LocalCheckInController c = localController(signedIn: false);
      await _open(tester, c);
      await tester.tap(find.text('Masuk untuk kumpulkan Kelopak'));
      expect(c.actions.where((String a) => a == 'openLogin'), hasLength(1));
      expect(find.textContaining('Streak'), findsNothing);
    });
  });

  group('CheckInPage tombol utama', () {
    testWidgets('siap klaim: label, hadiah, saldo, streak', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController());
      expect(find.text('Check-in sekarang'), findsOneWidget);
      expect(find.text('24 Kelopak'), findsOneWidget);
      expect(
        find.text('Streak 3 hari · jangan terlewat ya, Babes'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _primary,
          matching: find.text('+1 Kelopak hari ini'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('hari bonus menyebut +4', (WidgetTester tester) async {
      await _open(tester, localController(streak: 6));
      expect(
        find.descendant(
          of: _primary,
          matching: find.text('+4 Kelopak, termasuk bonus +3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('hari ke-30 menyebut produk gratis', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(streak: 29));
      expect(
        find.descendant(
          of: _primary,
          matching: find.text('+1 Kelopak dan 1 produk gratis'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sudah klaim: "Kembali besok" nonaktif dengan hitung mundur', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(streak: 4, claimedToday: true));
      expect(find.text('Kembali besok'), findsOneWidget);
      expect(find.text('Check-in lagi dalam 14:00:00'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Kembali besok, check-in buka lagi dalam 14 jam'),
        findsOneWidget,
      );
    });
  });

  group('CheckInPage klaim', () {
    testWidgets('klaim biasa: saldo naik, lembar hasil, suara', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c);
      await _claim(tester);
      expect(c.state.balance, 25);
      expect(find.text('Check-in hari ke-4 berhasil!'), findsOneWidget);
      expect(find.text('Streak 4 hari'), findsOneWidget);
      expect(
        find.text('Saldo kamu sekarang 25 Kelopak, senilai Rp2.500.'),
        findsOneWidget,
      );
      expect(find.text('3 hari lagi bonus +3 Kelopak'), findsOneWidget);
      expect(find.text('1 Kelopak = Rp100'), findsNothing);
      expect(c.actions, containsAllInOrder(<String>['cue:tap', 'cue:claim']));
      await tester.tap(find.text('Mantap'));
      await _pumpFor(tester, 800);
      expect(find.text('Check-in hari ke-4 berhasil!'), findsNothing);
      expect(find.text('Kembali besok'), findsOneWidget);
      expect(find.text('25 Kelopak'), findsOneWidget);
    });

    testWidgets('klaim bonus hari ke-7', (WidgetTester tester) async {
      final LocalCheckInController c = localController(streak: 6);
      await _open(tester, c);
      await _claim(tester);
      expect(find.text('Bonus!'), findsOneWidget);
      expect(find.text('Streak 7 hari'), findsWidgets);
      expect(
        find.text(
          'Termasuk bonus +3 Kelopak. Saldo kamu sekarang 28 Kelopak, '
          'senilai Rp2.800.',
        ),
        findsOneWidget,
      );
      expect(find.text('7 hari lagi bonus +3 Kelopak'), findsOneWidget);
      expect(c.actions, contains('cue:bonus'));
      expect(c.state.balance, 28);
    });

    testWidgets('klaim hari ke-30: produk, buka keranjang', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController(streak: 29);
      await _open(tester, c);
      await _claim(tester);
      expect(find.text('Selamat!'), findsOneWidget);
      expect(find.text('1 produk gratis'), findsWidgets);
      expect(find.text(demoRewardProduct.name), findsWidgets);
      expect(c.actions, contains('cue:winProduct'));
      await tester.tap(find.text('Lihat keranjang'));
      await _pumpFor(tester, 800);
      expect(c.actions.last, 'openCart');
    });

    testWidgets('"Belanja sekarang" di lembar hasil membuka toko', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c);
      await _claim(tester);
      await tester.tap(find.text('Belanja sekarang'));
      await _pumpFor(tester, 800);
      expect(c.actions.last, 'openShop');
    });

    testWidgets('Roda Sabtu siap: lembar hasil mengajak lanjut ke roda', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController(streak: 11, balance: 128)
        ..wheelReady = true;
      await _open(tester, c);
      await _claim(tester);
      expect(find.text('Check-in hari ke-12 berhasil!'), findsOneWidget);
      expect(
        find.text('Saldo kamu sekarang 129 Kelopak, senilai Rp12.900.'),
        findsOneWidget,
      );
      expect(find.text('2 hari lagi bonus +3 Kelopak'), findsOneWidget);
      expect(find.text('Belanja sekarang'), findsNothing);
      await tester.tap(find.text('Lanjut putar Roda Sabtu'));
      await _pumpFor(tester, 800);
      expect(c.actions.last, 'openWheel');
    });

    testWidgets('klaim gagal: pesan galat, tombol tetap siap', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController()..failNextClaim = true;
      await _open(tester, c);
      await _claim(tester);
      expect(
        find.text(
          'Check-in belum berhasil. Periksa koneksimu, lalu coba lagi.',
        ),
        findsOneWidget,
      );
      expect(c.actions, contains('cue:softError'));
      expect(find.text('Check-in sekarang'), findsOneWidget);
      expect(c.state.balance, 24);
    });

    testWidgets('tanpa lembar hasil bila host menampilkannya sendiri', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        checkInApp(
          CheckInPage(controller: c, showResultSheet: false),
          disableAnimations: true,
        ),
      );
      await _claim(tester);
      expect(find.text('Check-in hari ke-4 berhasil!'), findsNothing);
      expect(c.state.claimedToday, isTrue);
    });

    testWidgets('dengan animasi: koin, konfeti, dan Bipy selesai rapi', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c, disableAnimations: false);
      await tester.tap(_primary);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('24 Kelopak'), findsOneWidget);
      await _pumpFor(tester, 3000);
      expect(find.text('Check-in hari ke-4 berhasil!'), findsOneWidget);
      expect(c.state.balance, 25);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ketuk ganda hanya mengklaim sekali', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController(
        latency: const Duration(milliseconds: 200),
      );
      await _open(tester, c);
      await tester.tap(_primary);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(_primary, warnIfMissed: false);
      await _pumpFor(tester, 2500);
      expect(c.state.balance, 25);
      expect(c.state.streak, 4);
    });

    testWidgets('pergantian hari WIB membuka check-in lagi', (
      WidgetTester tester,
    ) async {
      DateTime now = DateTime.utc(2026, 11, 26, 16, 59, 58);
      final LocalCheckInController c = LocalCheckInController(
        clock: () => now,
        streak: 4,
        claimedToday: true,
      );
      await _open(tester, c);
      expect(find.text('Kembali besok'), findsOneWidget);
      now = DateTime.utc(2026, 11, 26, 17, 0, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Check-in sekarang'), findsOneWidget);
      expect(c.state.streak, 4);
    });
  });

  group('CheckInPage aksi lain', () {
    testWidgets('tombol suara mengikuti status host', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c);
      await tester.tap(find.byTooltip('Matikan suara'));
      await tester.pump();
      expect(c.state.soundOn, isFalse);
      expect(find.byTooltip('Nyalakan suara'), findsOneWidget);
    });

    testWidgets('tanpa status suara: tombol suara disembunyikan', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(soundOn: null));
      expect(find.byTooltip('Matikan suara'), findsNothing);
      expect(find.byTooltip('Nyalakan suara'), findsNothing);
    });

    testWidgets('"Aturan" membuka lembar aturan', (WidgetTester tester) async {
      await _open(tester, localController());
      await tester.tap(find.text('Aturan'));
      await _pumpFor(tester, 600);
      expect(find.text('Mengerti'), findsOneWidget);
    });

    testWidgets('kartu hadiah membuka detail produk', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c);
      await tester.tap(find.text('Hadiah: ${demoRewardProduct.name}'));
      expect(c.actions.last, 'openProduct:${demoRewardProduct.code}');
    });

    testWidgets('mengetuk Bipy memutar suara ketuk', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController c = localController();
      await _open(tester, c);
      await tester.tap(find.bySemanticsLabel('Bipy').first);
      expect(c.actions, contains('cue:tap'));
    });

    testWidgets('mengganti controller memindahkan pendengar', (
      WidgetTester tester,
    ) async {
      final LocalCheckInController a = localController();
      final LocalCheckInController b = localController(balance: 90);
      await _open(tester, a);
      await tester.pumpWidget(checkInPageApp(b, disableAnimations: true));
      await tester.pump();
      expect(find.text('90 Kelopak'), findsOneWidget);
      b.seed(streak: 0, claimedToday: false, balance: 91);
      await tester.pump();
      expect(find.text('91 Kelopak'), findsOneWidget);
      a.seed(streak: 0, claimedToday: false, balance: 5);
      await tester.pump();
      expect(find.text('5 Kelopak'), findsNothing);
      expect(find.text('91 Kelopak'), findsOneWidget);
    });
  });

  group('CheckInPage komposisi rancangan owner', () {
    testWidgets('tanpa strip "Minggu ini" dan kartu "Menuju produk gratis"', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(), size: const Size(390, 1300));
      expect(find.text('Minggu ini'), findsNothing);
      expect(find.text('Menuju produk gratis'), findsNothing);
      expect(find.text('Klaim Kelopak'), findsNothing);
      expect(find.byType(CheckInWeekStrip), findsNothing);
      expect(find.text('+1/hari'), findsOneWidget);
      expect(find.text('Ketentuan'), findsOneWidget);
    });

    testWidgets('kisi 30 hari utuh di lipatan pertama 390x844', (
      WidgetTester tester,
    ) async {
      await loadShotFonts(tester);
      await _open(tester, localController(streak: 11));
      final double barTop = tester.getTopLeft(_primary).dy;
      final Rect grid = tester.getRect(find.byType(CheckInMonthGrid));
      final Rect rules = tester.getRect(find.byType(CheckInHowTo));
      expect(grid.bottom, lessThanOrEqualTo(barTop));
      expect(rules.bottom, lessThan(grid.top));
      expect(find.text('Hari ini'), findsOneWidget);
    });

    testWidgets('baris di atas kisi: hari ke-N dan hadiah', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(streak: 11));
      expect(find.text('Hari ke-12 dari 30'), findsOneWidget);
      expect(find.text('Hadiah: ${demoRewardProduct.name}'), findsOneWidget);
    });

    testWidgets('siklus kedua: hari ini dan bonus cocok dengan kisi', (
      WidgetTester tester,
    ) async {
      await _open(tester, localController(streak: 31));
      expect(find.text('Minggu ini'), findsNothing);
      expect(find.text('Hari ke-2 dari 30'), findsOneWidget);
      expect(find.text('Hari 1'), findsOneWidget);
      expect(find.text('Hari 2'), findsNothing);
      expect(find.text('Hari ini'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Kalender 30 hari'),
      );
      expect(node.value, contains('Hari ini hari ke-2.'));
      expect(node.value, contains('ke-5, ke-12, ke-19, ke-26'));
      expect(find.text('+4'), findsNWidgets(4));
    });
  });

  group('CheckInPage teks 200% di lebar 360 tanpa luapan', () {
    final Map<String, LocalCheckInController Function()> states =
        <String, LocalCheckInController Function()>{
          'tamu': () => localController(signedIn: false),
          'siap': localController,
          'bonus': () => localController(streak: 6),
          'sudah': () => localController(streak: 11, claimedToday: true),
          'hari 30': () => localController(streak: 29),
        };
    for (final Brightness brightness in Brightness.values) {
      for (final MapEntry<String, LocalCheckInController Function()> entry
          in states.entries) {
        testWidgets('${entry.key}, ${brightness.name}', (
          WidgetTester tester,
        ) async {
          await loadShotFonts(tester);
          await _open(
            tester,
            entry.value(),
            size: const Size(360, 3200),
            textScale: 2,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(_primary, findsOneWidget);
        });
      }
    }

    testWidgets('lebar 320, teks 100%', (WidgetTester tester) async {
      await loadShotFonts(tester);
      await _open(
        tester,
        localController(streak: 6),
        size: const Size(320, 2000),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
