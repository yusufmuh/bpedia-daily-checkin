import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInViewState _state(int streak, {bool claimed = false}) => CheckInViewState(
  signedIn: true,
  balance: 0,
  streak: streak,
  claimedToday: claimed,
);

void main() {
  group('formatRupiah', () {
    test('ribuan dipisah titik', () {
      expect(formatRupiah(19900), 'Rp19.900');
      expect(formatRupiah(1000000), 'Rp1.000.000');
    });

    test('nol dan ratusan', () {
      expect(formatRupiah(0), 'Rp0');
      expect(formatRupiah(100), 'Rp100');
    });

    test('negatif', () {
      expect(formatRupiah(-5000), '-Rp5.000');
    });
  });

  group('countdownClock', () {
    test('jam, menit, detik dua digit', () {
      expect(countdownClock(const Duration(hours: 14)), '14:00:00');
      expect(countdownClock(const Duration(seconds: 3661)), '01:01:01');
    });

    test('negatif menjadi nol', () {
      expect(countdownClock(const Duration(seconds: -5)), '00:00:00');
    });
  });

  group('countdownSpoken', () {
    test('kurang dari semenit', () {
      expect(
        countdownSpoken(const Duration(seconds: 30)),
        'kurang dari 1 menit',
      );
      expect(
        countdownSpoken(const Duration(seconds: -1)),
        'kurang dari 1 menit',
      );
    });

    test('menit saja, jam saja, jam dan menit', () {
      expect(countdownSpoken(const Duration(minutes: 45)), '45 menit');
      expect(countdownSpoken(const Duration(hours: 2)), '2 jam');
      expect(
        countdownSpoken(const Duration(hours: 2, minutes: 5)),
        '2 jam 5 menit',
      );
    });
  });

  group('balanceSentence dan nextBonusNote', () {
    test('saldo beserta nilai rupiah', () {
      expect(
        balanceSentence(129),
        'Saldo kamu sekarang 129 Kelopak, senilai Rp12.900.',
      );
      expect(balanceSentence(0), 'Saldo kamu sekarang 0 Kelopak, senilai Rp0.');
    });

    test('sisa hari menuju bonus berikutnya', () {
      expect(nextBonusNote(12), '2 hari lagi bonus +3 Kelopak');
      expect(nextBonusNote(6), '1 hari lagi bonus +3 Kelopak');
      expect(nextBonusNote(7), '7 hari lagi bonus +3 Kelopak');
      expect(nextBonusNote(0), '7 hari lagi bonus +3 Kelopak');
    });
  });

  group('streakMessage', () {
    test('tamu diajak masuk', () {
      expect(
        streakMessage(const CheckInViewState.guest()),
        'Masuk dulu, lalu klaim Kelopak pertamamu, Babes.',
      );
    });

    test('belum ada streak', () {
      expect(streakMessage(_state(0)), startsWith('Mulai streak hari ini'));
    });

    test('hari biasa belum klaim', () {
      expect(
        streakMessage(_state(3)),
        'Streak 3 hari · jangan terlewat ya, Babes',
      );
    });

    test('hari bonus belum klaim', () {
      expect(
        streakMessage(_state(6)),
        'Streak 6 hari · hari ini bonus +3 Kelopak menunggumu',
      );
    });

    test('hari produk belum klaim', () {
      expect(
        streakMessage(_state(29)),
        'Streak 29 hari · hari ini produk gratismu siap diklaim, Babes',
      );
    });

    test('sudah klaim di hari bonus', () {
      expect(
        streakMessage(_state(7, claimed: true)),
        'Streak 7 hari · bonus +3 Kelopak sudah masuk',
      );
    });

    test('sudah klaim di hari biasa menyebut sisa hari', () {
      expect(
        streakMessage(_state(12, claimed: true)),
        'Streak 12 hari · 2 hari lagi menuju bonus +3 Kelopak',
      );
    });
  });

  group('weekTileSemantics', () {
    test('sudah, hari ini, belum', () {
      expect(
        weekTileSemantics(day: 2, filled: 3, claimedToday: false),
        'Hari 2, sudah check-in',
      );
      expect(
        weekTileSemantics(day: 4, filled: 3, claimedToday: false),
        'Hari 4, hari ini, belum check-in',
      );
      expect(
        weekTileSemantics(day: 5, filled: 3, claimedToday: false),
        'Hari 5, belum',
      );
    });

    test('setelah klaim tidak ada hari ini', () {
      expect(
        weekTileSemantics(day: 4, filled: 3, claimedToday: true),
        'Hari 4, belum',
      );
    });

    test('hari 7 menyebut bonus', () {
      expect(
        weekTileSemantics(day: 7, filled: 6, claimedToday: false),
        'Hari 7, hari ini, belum check-in, bonus 3 Kelopak',
      );
    });
  });
}
