import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/check_in_harness.dart';
import '../support/shot.dart';

Widget _host(
  Widget child, {
  double width = 390,
  double textScale = 1,
  bool disableAnimations = true,
  Brightness brightness = Brightness.light,
}) {
  return checkInApp(
    Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
    brightness: brightness,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
}

Future<void> _pumpFor(WidgetTester tester, int milliseconds) async {
  for (int t = 0; t < milliseconds; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _inStrip(Finder matching) =>
    find.descendant(of: find.byType(CheckInWeekStrip), matching: matching);

void main() {
  group('CheckInWeekStrip semantics', () {
    testWidgets('hari ke-4 adalah hari ini', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 3, claimedToday: false)),
      );
      expect(
        find.bySemanticsLabel('Hari 4, hari ini, belum check-in'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Hari 3, sudah check-in'), findsOneWidget);
      expect(find.bySemanticsLabel('Hari 5, belum'), findsOneWidget);
    });

    testWidgets('belum ada check-in: hari 1 adalah hari ini', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 0, claimedToday: false)),
      );
      expect(
        find.bySemanticsLabel('Hari 1, hari ini, belum check-in'),
        findsOneWidget,
      );
    });

    testWidgets('hari ke-7 hari ini menyebut bonus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 6, claimedToday: false)),
      );
      expect(
        find.bySemanticsLabel(
          'Hari 7, hari ini, belum check-in, bonus 3 Kelopak',
        ),
        findsOneWidget,
      );
    });

    testWidgets('7 hari lengkap: semua sudah', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 7, claimedToday: true)),
      );
      for (int day = 1; day <= 6; day++) {
        expect(
          find.bySemanticsLabel('Hari $day, sudah check-in'),
          findsOneWidget,
        );
      }
      expect(
        find.bySemanticsLabel('Hari 7, sudah check-in, bonus 3 Kelopak'),
        findsOneWidget,
      );
    });

    testWidgets('sudah check-in hari ini: tidak ada ubin hari ini', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 4, claimedToday: true)),
      );
      expect(find.bySemanticsLabel(RegExp('hari ini')), findsNothing);
      expect(find.text('Hari ini'), findsNothing);
    });

    testWidgets('teks "Hari N" tidak dibacakan dua kali', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 3, claimedToday: false)),
      );
      expect(find.text('Hari 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Hari 2'), findsNothing);
      expect(find.bySemanticsLabel('+1'), findsNothing);
    });

    testWidgets('nilai filled di luar 0..7 dibatasi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 12, claimedToday: false)),
      );
      expect(
        find.bySemanticsLabel('Hari 7, sudah check-in, bonus 3 Kelopak'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: -3, claimedToday: false)),
      );
      expect(
        find.bySemanticsLabel('Hari 1, hari ini, belum check-in'),
        findsOneWidget,
      );
    });
  });

  group('CheckInWeekStrip ubin', () {
    testWidgets('pita "Hari ini" dan "Bonus" pada ubin yang tepat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 2, claimedToday: false)),
      );
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Bonus'), findsOneWidget);
      expect(find.text('+4'), findsOneWidget);
      expect(find.text('+1'), findsNWidgets(6));
    });

    testWidgets('hari ke-7 hari ini: pita "Hari ini" menggantikan "Bonus"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 6, claimedToday: false)),
      );
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Bonus'), findsNothing);
    });

    testWidgets('jangkar koin terpasang di ubin hari ini', (
      WidgetTester tester,
    ) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        _host(
          CheckInWeekStrip(
            filled: 3,
            claimedToday: false,
            todayAnchorKey: anchor,
          ),
        ),
      );
      expect(anchor.currentContext, isNotNull);
      final Offset art = tester.getCenter(find.byKey(anchor));
      final Offset label = tester.getCenter(find.text('Hari 4'));
      expect((art.dx - label.dx).abs(), lessThan(2));
    });

    testWidgets('teks 100% di 412 dp: tujuh ubin dalam satu baris', (
      WidgetTester tester,
    ) async {
      await loadShotFonts(tester);
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 3, claimedToday: false),
          width: 412,
        ),
      );
      final double first = tester.getTopLeft(find.text('Hari 1')).dy;
      for (int day = 2; day <= 7; day++) {
        expect(tester.getTopLeft(find.text('Hari $day')).dy, first);
      }
    });

    testWidgets('360 dp, teks 200%: ubin turun baris tanpa luapan', (
      WidgetTester tester,
    ) async {
      await loadShotFonts(tester);
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 3, claimedToday: false),
          width: 360,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final double first = tester.getTopLeft(find.text('Hari 1')).dy;
      expect(tester.getTopLeft(find.text('Hari 7')).dy, greaterThan(first));
      final Rect pill = tester.getRect(find.text('Hari ini'));
      final Rect value = tester.getRect(
        find.descendant(
          of: find.bySemanticsLabel('Hari 4, hari ini, belum check-in'),
          matching: find.text('+1'),
        ),
      );
      expect(pill.bottom, lessThanOrEqualTo(value.top));
    });
  });

  group('CheckInWeekStrip gerak', () {
    testWidgets('ubin hari ini berdenyut antara 1,0 dan 1,06', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 3, claimedToday: false),
          disableAnimations: false,
        ),
      );
      final ScaleTransition pulse = tester.widget<ScaleTransition>(
        _inStrip(find.byType(ScaleTransition)),
      );
      expect(pulse.scale.value, 1);
      await _pumpFor(tester, 800);
      expect(pulse.scale.value, greaterThan(1));
      expect(pulse.scale.value, lessThanOrEqualTo(CheckInWeekStrip.pulseScale));
    });

    testWidgets('diam bila animasi dimatikan sistem', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 3, claimedToday: false)),
      );
      final ScaleTransition pulse = tester.widget<ScaleTransition>(
        _inStrip(find.byType(ScaleTransition)),
      );
      await _pumpFor(tester, 800);
      expect(pulse.scale.value, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('tidak ada denyut setelah check-in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 4, claimedToday: true),
          disableAnimations: false,
        ),
      );
      expect(_inStrip(find.byType(ScaleTransition)), findsNothing);
    });

    testWidgets('klaim memicu stempel lalu berhenti', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 3, claimedToday: false),
          disableAnimations: false,
        ),
      );
      await tester.pumpWidget(
        _host(
          const CheckInWeekStrip(filled: 4, claimedToday: true),
          disableAnimations: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await _pumpFor(tester, 1500);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('kurangi gerak: klaim tanpa stempel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 3, claimedToday: false)),
      );
      await tester.pumpWidget(
        _host(const CheckInWeekStrip(filled: 4, claimedToday: true)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('CheckInMonthGrid', () {
    testWidgets('ringkasan semantics menyebut hari bonus siklus pertama', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInMonthGrid(day: 3, claimedToday: false)),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Kalender 30 hari'),
      );
      expect(node.value, contains('3 dari 30 hari sudah check-in'));
      expect(node.value, contains('ke-7, ke-14, ke-21, ke-28'));
      expect(node.value, contains('Hari ke-30 dapat 1 produk gratis'));
    });

    testWidgets('siklus kedua: bonus mengikuti hari streak sebenarnya', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CheckInMonthGrid(day: 4, claimedToday: false, cycleStart: 30),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Kalender 30 hari'),
      );
      expect(node.value, contains('ke-5, ke-12, ke-19, ke-26'));
      expect(find.text('+3'), findsNWidgets(4));
    });

    testWidgets('30 sel bernomor, spanduk, dan legenda', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckInMonthGrid(day: 10, claimedToday: true)),
      );
      for (int day = 1; day <= 30; day++) {
        expect(find.text('$day'), findsWidgets);
      }
      expect(find.text('30 hari = 1 produk gratis'), findsOneWidget);
      expect(find.text('+1 Kelopak'), findsOneWidget);
      expect(find.text('Bonus +3 Kelopak'), findsOneWidget);
      expect(find.text('Produk gratis'), findsOneWidget);
    });

    for (final Brightness brightness in Brightness.values) {
      testWidgets('360 dp, teks 200%, ${brightness.name}: tanpa luapan', (
        WidgetTester tester,
      ) async {
        await loadShotFonts(tester);
        await tester.pumpWidget(
          _host(
            const CheckInMonthGrid(day: 29, claimedToday: false),
            width: 360,
            textScale: 2,
            brightness: brightness,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CheckInMonthProgress', () {
    testWidgets('semantics: label dan nilai', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CheckInMonthProgress(day: 3)));
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Progres produk gratis'),
      );
      expect(node.value, '3 dari 30 hari');
      expect(find.text('27 hari lagi menuju produk gratis'), findsOneWidget);
    });

    testWidgets('hari dibatasi 0..30', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CheckInMonthProgress(day: 45)));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Progres produk gratis'))
            .value,
        '30 dari 30 hari',
      );
      expect(find.textContaining('Tuntas!'), findsOneWidget);
      await tester.pumpWidget(_host(const CheckInMonthProgress(day: -2)));
      expect(find.text('Mulai dari hari ke-1'), findsOneWidget);
    });

    testWidgets('tulip tumbuh bertahap mengikuti tonggak', (
      WidgetTester tester,
    ) async {
      const Map<int, int> stages = <int, int>{
        0: 1,
        6: 1,
        7: 2,
        14: 3,
        21: 4,
        29: 4,
        30: 5,
      };
      for (final MapEntry<int, int> entry in stages.entries) {
        await tester.pumpWidget(_host(CheckInMonthProgress(day: entry.key)));
        expect(
          find.bySemanticsLabel('Tulip tahap ${entry.value} dari 5'),
          findsOneWidget,
          reason: 'hari ${entry.key}',
        );
      }
    });

    testWidgets('TulipPot membatasi tahap', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const TulipPot(stage: 9)));
      expect(find.bySemanticsLabel('Tulip tahap 5 dari 5'), findsOneWidget);
      await tester.pumpWidget(_host(const TulipPot(stage: -1)));
      expect(find.bySemanticsLabel('Tulip tahap 1 dari 5'), findsOneWidget);
    });
  });

  group('CheckInRewardCard', () {
    testWidgets('produk host: nama, gratis, harga dicoret, bisa dibuka', (
      WidgetTester tester,
    ) async {
      int opened = 0;
      await tester.pumpWidget(
        _host(
          CheckInRewardCard(product: demoRewardProduct, onOpen: () => opened++),
        ),
      );
      expect(find.text(demoRewardProduct.name), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Rp19.900'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Lihat produk$')), findsOneWidget);
      await tester.tap(find.text(demoRewardProduct.name));
      expect(opened, 1);
    });

    testWidgets('tanpa produk: kartu hadiah umum', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CheckInRewardCard()));
      expect(
        find.bySemanticsLabel(
          'Hadiah hari ke-30: 1 produk gratis, dikirim bersama pesanan '
          'belanjamu',
        ),
        findsOneWidget,
      );
    });

    testWidgets('produk tanpa onOpen tidak bisa diketuk', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CheckInRewardCard(product: demoRewardProduct)),
      );
      expect(find.bySemanticsLabel(RegExp('Lihat produk')), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(demoRewardProduct.name)),
        findsOneWidget,
      );
    });
  });

  group('CheckInHowTo dan aturan', () {
    testWidgets('tiga langkah dan tautan syarat', (WidgetTester tester) async {
      int terms = 0;
      await tester.pumpWidget(_host(CheckInHowTo(onOpenTerms: () => terms++)));
      expect(find.text('Check-in tiap hari'), findsOneWidget);
      expect(find.text('7 hari beruntun'), findsOneWidget);
      expect(find.text('30 hari tanpa putus'), findsOneWidget);
      await tester.tap(find.text('Syarat dan ketentuan'));
      expect(terms, 1);
    });

    testWidgets('lembar aturan memuat semua baris dan bisa ditutup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => showCheckInRulesSheet(context),
              child: const Text('Buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await _pumpFor(tester, 600);
      for (final String line in checkInRuleLines) {
        expect(find.text(line), findsOneWidget);
      }
      await tester.tap(find.text('Mengerti'));
      await _pumpFor(tester, 600);
      expect(find.text('Mengerti'), findsNothing);
    });

    test('baris aturan memuat angka ekonomi yang benar', () {
      final String all = checkInRuleLines.join(' ');
      expect(all, contains('+1 Kelopak'));
      expect(all, contains('+3'));
      expect(all, contains('30'));
    });
  });

  group('LivelyPose', () {
    testWidgets('bergerak bila animasi aktif', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const LivelyPose(image: CheckInArt.poseStar, height: 120),
          disableAnimations: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.bySemanticsLabel('Bipy'), findsOneWidget);
    });

    testWidgets('diam saat kurangi gerak', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const LivelyPose(image: CheckInArt.poseStar, height: 120)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
