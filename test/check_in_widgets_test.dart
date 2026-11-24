import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/brand_theme.dart';

const Key _currencyKey = ValueKey<String>('kelopak');
const Key _bonusKey = ValueKey<String>('hadiah');
const Key _rewardKey = ValueKey<String>('produk');
const String _hint = 'Kembali besok mulai 00.00 WIB untuk Hari ke-4';

CheckInWeekTrack _track({
  required int filled,
  required bool claimedToday,
  Widget? bonusIcon,
}) {
  return CheckInWeekTrack(
    filled: filled,
    claimedToday: claimedToday,
    currencyIcon: const Icon(Icons.local_florist, key: _currencyKey),
    bonusIcon: bonusIcon,
  );
}

List<String> _slotLabels(WidgetTester tester) {
  return <String>[
    for (int day = 1; day <= 7; day++)
      tester.getSemantics(find.bySemanticsLabel(RegExp('^Hari $day,'))).label,
  ];
}

Finder get _pulse => find.descendant(
  of: find.byType(CheckInWeekTrack),
  matching: find.byType(ScaleTransition),
);

Finder get _filledButton =>
    find.byWidgetPredicate((Widget widget) => widget is FilledButton);

void main() {
  group('CheckInWeekTrack semantics', () {
    testWidgets('hari ke-4 adalah hari ini', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(_track(filled: 3, claimedToday: false)));
      expect(_slotLabels(tester), <String>[
        'Hari 1, sudah check-in',
        'Hari 2, sudah check-in',
        'Hari 3, sudah check-in',
        'Hari 4, hari ini, belum check-in',
        'Hari 5, belum',
        'Hari 6, belum',
        'Hari 7, belum, bonus 3 Kelopak',
      ]);
    });

    testWidgets('belum ada check-in: hari 1 adalah hari ini', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 0, claimedToday: false)));
      expect(
        find.bySemanticsLabel('Hari 1, hari ini, belum check-in'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Hari 2, belum'), findsOneWidget);
    });

    testWidgets('hari ke-7 hari ini menyebut bonus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 6, claimedToday: false)));
      expect(
        find.bySemanticsLabel(
          'Hari 7, hari ini, belum check-in, bonus 3 Kelopak',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Hari 6, sudah check-in'), findsOneWidget);
    });

    testWidgets('7 hari lengkap: semua mekar', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(_track(filled: 7, claimedToday: true)));
      expect(_slotLabels(tester), <String>[
        for (int day = 1; day <= 6; day++) 'Hari $day, sudah check-in',
        'Hari 7, sudah check-in, bonus 3 Kelopak',
      ]);
      expect(find.byKey(_currencyKey), findsNothing);
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('sudah check-in hari ini: tidak ada slot hari ini', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 3, claimedToday: true)));
      expect(_slotLabels(tester), <String>[
        'Hari 1, sudah check-in',
        'Hari 2, sudah check-in',
        'Hari 3, sudah check-in',
        'Hari 4, belum',
        'Hari 5, belum',
        'Hari 6, belum',
        'Hari 7, belum, bonus 3 Kelopak',
      ]);
      expect(find.byKey(_currencyKey), findsNothing);
    });

    testWidgets('teks "Hari N" tidak dibacakan dua kali', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 2, claimedToday: false)));
      for (int day = 1; day <= 7; day++) {
        expect(find.text('Hari $day'), findsOneWidget);
        expect(find.bySemanticsLabel('Hari $day'), findsNothing);
      }
    });

    testWidgets('nilai filled di luar 0..7 dibatasi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: -4, claimedToday: false)));
      expect(
        find.bySemanticsLabel('Hari 1, hari ini, belum check-in'),
        findsOneWidget,
      );
      await tester.pumpWidget(hostApp(_track(filled: 12, claimedToday: false)));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel(RegExp('sudah check-in')), findsNWidgets(7));
      expect(find.byKey(_currencyKey), findsNothing);
    });
  });

  group('CheckInWeekTrack slot', () {
    testWidgets('ikon Kelopak 16 dp hanya di slot hari ini', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 2, claimedToday: false)));
      expect(find.byKey(_currencyKey), findsOneWidget);
      expect(tester.getSize(find.byKey(_currencyKey)), const Size(16, 16));
      expect(
        find.descendant(
          of: find.bySemanticsLabel('Hari 3, hari ini, belum check-in'),
          matching: find.byKey(_currencyKey),
        ),
        findsOneWidget,
      );
    });

    testWidgets('slot 7 memakai bonusIcon host', (WidgetTester tester) async {
      await tester.pumpWidget(
        hostApp(
          _track(
            filled: 1,
            claimedToday: true,
            bonusIcon: const Icon(Icons.redeem, key: _bonusKey),
          ),
        ),
      );
      expect(find.byKey(_bonusKey), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard), findsNothing);
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('slot 7 tanpa bonusIcon memakai ikon kado', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 1, claimedToday: true)));
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    });

    testWidgets('label "Hari N" muat satu baris di slot sempit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hostApp(
          Center(
            child: SizedBox(
              width: 220,
              child: _track(filled: 4, claimedToday: false),
            ),
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      const double slotWidth = (220 - 6 * 6) / 7;
      for (int day = 1; day <= 7; day++) {
        final Rect label = tester.getRect(find.text('Hari $day'));
        expect(label.width, lessThanOrEqualTo(slotWidth + 0.01));
      }
    });
  });

  group('CheckInWeekTrack pulse', () {
    testWidgets('slot hari ini berdenyut antara 1,0 dan 1,06', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hostApp(
          _track(filled: 2, claimedToday: false),
          disableAnimations: false,
        ),
      );
      expect(_pulse, findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      double lowest = double.infinity;
      double highest = double.negativeInfinity;
      for (int frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        final double scale = tester.widget<ScaleTransition>(_pulse).scale.value;
        lowest = scale < lowest ? scale : lowest;
        highest = scale > highest ? scale : highest;
      }
      expect(lowest, greaterThanOrEqualTo(1.0));
      expect(lowest, lessThan(1.01));
      expect(highest, lessThanOrEqualTo(1.06 + 1e-9));
      expect(highest, greaterThan(1.05));
    });

    testWidgets('diam bila animasi dimatikan sistem', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(_track(filled: 2, claimedToday: false)));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.widget<ScaleTransition>(_pulse).scale.value, 1.0);
    });

    testWidgets('berhenti dan berjalan lagi mengikuti preferensi', (
      WidgetTester tester,
    ) async {
      final CheckInWeekTrack track = _track(filled: 2, claimedToday: false);
      await tester.pumpWidget(hostApp(track, disableAnimations: false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(hostApp(track));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.widget<ScaleTransition>(_pulse).scale.value, 1.0);

      await tester.pumpWidget(hostApp(track, disableAnimations: false));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('tidak ada denyut setelah check-in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hostApp(
          _track(filled: 3, claimedToday: true),
          disableAnimations: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pulse, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('CheckInMonthProgress', () {
    testWidgets('semantics: label dan nilai', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const CheckInMonthProgress(day: 12)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Progres produk gratis')),
        isSemantics(label: 'Progres produk gratis', value: '12 dari 30 hari'),
      );
      expect(find.text('Menuju produk gratis'), findsOneWidget);
      expect(find.text('12 dari 30 hari'), findsOneWidget);
      expect(find.bySemanticsLabel('Menuju produk gratis'), findsNothing);
    });

    testWidgets('hari dibatasi 0..30', (WidgetTester tester) async {
      await tester.pumpWidget(hostApp(const CheckInMonthProgress(day: 45)));
      expect(find.text('30 dari 30 hari'), findsOneWidget);
      await tester.pumpWidget(hostApp(const CheckInMonthProgress(day: -3)));
      expect(find.text('0 dari 30 hari'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Progres produk gratis')),
        isSemantics(value: '0 dari 30 hari'),
      );
    });

    testWidgets('rewardImage host 28 dp', (WidgetTester tester) async {
      await tester.pumpWidget(
        hostApp(
          const CheckInMonthProgress(
            day: 30,
            rewardImage: Icon(Icons.card_giftcard, key: _rewardKey),
          ),
        ),
      );
      expect(find.byKey(_rewardKey), findsOneWidget);
      expect(tester.getSize(find.byKey(_rewardKey)), const Size(28, 28));
      expect(find.byIcon(Icons.redeem), findsNothing);
    });

    testWidgets('tanpa rewardImage memakai Icons.redeem', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hostApp(const CheckInMonthProgress(day: 3)));
      expect(find.byIcon(Icons.redeem), findsOneWidget);
    });
  });

  group('CheckInClaimButton', () {
    testWidgets('siap: "Ambil 1 Kelopak", lebar penuh, min. 52 dp', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        hostApp(
          CheckInClaimButton(
            state: CheckInButtonState.ready,
            onPressed: () => taps++,
            claimedHint: _hint,
          ),
        ),
      );
      expect(find.text('Ambil 1 Kelopak'), findsOneWidget);
      expect(find.byIcon(Icons.local_florist), findsOneWidget);
      expect(find.text('Sudah check-in hari ini'), findsNothing);
      expect(find.text(_hint), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final Size size = tester.getSize(_filledButton);
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, 800 - 32);
      expect(
        tester.getSemantics(_filledButton),
        isSemantics(
          label: 'Ambil 1 Kelopak',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(_filledButton);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('sudah: nonaktif, ikon centang, petunjuk di bawah', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        hostApp(
          CheckInClaimButton(
            state: CheckInButtonState.claimed,
            onPressed: () => taps++,
            claimedHint: _hint,
          ),
        ),
      );
      expect(find.text('Sudah check-in hari ini'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Ambil 1 Kelopak'), findsNothing);
      expect(tester.widget<FilledButton>(_filledButton).enabled, isFalse);
      expect(
        tester.getSemantics(_filledButton),
        isSemantics(
          label: 'Sudah check-in hari ini',
          isButton: true,
          isEnabled: false,
        ),
      );

      final Finder hint = find.text(_hint);
      expect(hint, findsOneWidget);
      expect(
        tester.getTopLeft(hint).dy,
        greaterThan(tester.getBottomLeft(_filledButton).dy),
      );
      final Text hintText = tester.widget<Text>(hint);
      expect(hintText.textAlign, TextAlign.center);

      await tester.tap(_filledButton, warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('siap tanpa onPressed tetap tampil tetapi nonaktif', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hostApp(
          const CheckInClaimButton(
            state: CheckInButtonState.ready,
            onPressed: null,
            claimedHint: _hint,
          ),
        ),
      );
      expect(find.text('Ambil 1 Kelopak'), findsOneWidget);
      expect(tester.widget<FilledButton>(_filledButton).enabled, isFalse);
    });

    testWidgets('petunjuk kosong tidak menambah teks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hostApp(
          const CheckInClaimButton(
            state: CheckInButtonState.claimed,
            onPressed: null,
            claimedHint: '',
          ),
        ),
      );
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('Teks 200% pada layar 360 x 740', () {
    const List<(int, bool, int, CheckInButtonState)> states =
        <(int, bool, int, CheckInButtonState)>[
          (0, false, 0, CheckInButtonState.ready),
          (3, false, 10, CheckInButtonState.ready),
          (6, false, 27, CheckInButtonState.ready),
          (4, true, 18, CheckInButtonState.claimed),
          (7, true, 30, CheckInButtonState.claimed),
        ];

    for (final double width in <double>[360, 320]) {
      for (final Brightness brightness in Brightness.values) {
        for (final (int, bool, int, CheckInButtonState) state in states) {
          testWidgets('lebar $width, ${brightness.name}, filled ${state.$1}, '
              'hari ${state.$3}: tanpa overflow', (WidgetTester tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 740);
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              hostApp(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: <Widget>[
                    _track(
                      filled: state.$1,
                      claimedToday: state.$2,
                      bonusIcon: const Icon(Icons.card_giftcard),
                    ),
                    CheckInMonthProgress(
                      day: state.$3,
                      rewardImage: const Icon(Icons.redeem),
                    ),
                    CheckInClaimButton(
                      state: state.$4,
                      onPressed: () {},
                      claimedHint: _hint,
                    ),
                  ],
                ),
                textScale: 2,
                brightness: brightness,
              ),
            );
            await tester.pump(const Duration(milliseconds: 16));
            expect(tester.takeException(), isNull);
            expect(find.byType(CheckInWeekTrack), findsOneWidget);
            expect(find.byType(CheckInMonthProgress), findsOneWidget);
            expect(find.byType(CheckInClaimButton), findsOneWidget);
          });
        }
      }
    }
  });
}
