import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/brand_theme.dart';

/// Host-side state, wired exactly like the README example.
class _CheckInHost extends StatefulWidget {
  const _CheckInHost({super.key, required this.today});

  final int today;

  @override
  State<_CheckInHost> createState() => _CheckInHostState();
}

class _CheckInHostState extends State<_CheckInHost> {
  int? lastClaimDay;
  int streak = 0;
  int balance = 0;
  int products = 0;

  void _claim() {
    final CheckInAward? award = evaluateCheckIn(
      today: widget.today,
      lastClaimDay: lastClaimDay,
      streak: streak,
    );
    if (award == null) return;
    setState(() {
      lastClaimDay = widget.today;
      streak = award.streak;
      balance += award.totalKelopak;
      if (award.productEntitled) products++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int today = widget.today;
    final bool claimed = isClaimedOn(today: today, lastClaimDay: lastClaimDay);
    final int live = liveStreak(
      today: today,
      lastClaimDay: lastClaimDay,
      streak: streak,
    );
    return ListView(
      children: <Widget>[
        Text('Saldo $balance Kelopak'),
        CheckInWeekTrack(
          filled: filledInWeek(liveStreak: live, claimedToday: claimed),
          claimedToday: claimed,
          currencyIcon: const Icon(Icons.local_florist),
        ),
        const SizedBox(height: 16),
        CheckInClaimButton(
          state: claimed
              ? CheckInButtonState.claimed
              : CheckInButtonState.ready,
          onPressed: _claim,
          claimedHint:
              'Kembali besok mulai 00.00 WIB untuk Hari ke-${live + 1}',
        ),
        const SizedBox(height: 24),
        CheckInMonthProgress(
          day: dayInMonthCycle(liveStreak: live, claimedToday: claimed),
        ),
      ],
    );
  }
}

const Key _hostKey = ValueKey<String>('host');

Future<void> _showDay(WidgetTester tester, int today) =>
    tester.pumpWidget(hostApp(_CheckInHost(key: _hostKey, today: today)));

Future<void> _tapClaim(WidgetTester tester) async {
  await tester.tap(find.text('Ambil 1 Kelopak'));
  await tester.pump();
}

void _expectTodaySlot(int day) {
  expect(
    find.bySemanticsLabel(RegExp('^Hari $day, hari ini, belum check-in')),
    findsOneWidget,
  );
}

void main() {
  testWidgets('alur seminggu, pergantian minggu, dan bolong', (
    WidgetTester tester,
  ) async {
    int today = 20781;
    await _showDay(tester, today);
    _expectTodaySlot(1);
    expect(find.text('0 dari 30 hari'), findsOneWidget);

    await _tapClaim(tester);
    expect(find.text('Saldo 1 Kelopak'), findsOneWidget);
    expect(find.text('Sudah check-in hari ini'), findsOneWidget);
    expect(
      find.text('Kembali besok mulai 00.00 WIB untuk Hari ke-2'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Hari 1, sudah check-in'), findsOneWidget);
    expect(find.text('1 dari 30 hari'), findsOneWidget);

    await tester.tap(find.text('Sudah check-in hari ini'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Saldo 1 Kelopak'), findsOneWidget);

    for (int day = 2; day <= 7; day++) {
      today++;
      await _showDay(tester, today);
      _expectTodaySlot(day);
      await _tapClaim(tester);
    }
    expect(find.text('Saldo 10 Kelopak'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Hari 7, sudah check-in, bonus 3 Kelopak'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('sudah check-in')), findsNWidgets(7));
    expect(find.text('7 dari 30 hari'), findsOneWidget);

    today++;
    await _showDay(tester, today);
    _expectTodaySlot(1);
    expect(find.text('7 dari 30 hari'), findsOneWidget);
    expect(find.text('Ambil 1 Kelopak'), findsOneWidget);

    today += 2;
    await _showDay(tester, today);
    _expectTodaySlot(1);
    expect(find.text('0 dari 30 hari'), findsOneWidget);

    await _tapClaim(tester);
    expect(find.text('Saldo 11 Kelopak'), findsOneWidget);
    expect(find.text('1 dari 30 hari'), findsOneWidget);
    expect(
      find.text('Kembali besok mulai 00.00 WIB untuk Hari ke-2'),
      findsOneWidget,
    );
  });

  testWidgets('hari ke-30 mengisi progres penuh dan memberi produk', (
    WidgetTester tester,
  ) async {
    int today = 20781;
    for (int day = 1; day <= 30; day++) {
      await _showDay(tester, today);
      await _tapClaim(tester);
      today++;
    }
    expect(find.text('Saldo 42 Kelopak'), findsOneWidget);
    expect(find.text('30 dari 30 hari'), findsOneWidget);
    final _CheckInHostState state = tester.state(find.byKey(_hostKey));
    expect(state.products, 1);
    expect(state.streak, 30);

    await _showDay(tester, today);
    expect(find.text('0 dari 30 hari'), findsOneWidget);
    _expectTodaySlot(3);
  });
}
