import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInViewState _state(int streak, {bool claimed = false}) => CheckInViewState(
  signedIn: true,
  balance: 0,
  streak: streak,
  claimedToday: claimed,
);

void main() {
  group('CheckInViewState turunan', () {
    test('streak 3 belum klaim: hari ke-4 biasa', () {
      final CheckInViewState s = _state(3);
      expect(s.weekFilled, 3);
      expect(s.monthDay, 3);
      expect(s.todayStreakDay, 4);
      expect(s.monthCycleStart, 0);
      expect(s.todayIsBonus, isFalse);
      expect(s.todayGrantsProduct, isFalse);
      expect(s.todayKelopak, 1);
      expect(s.daysToBonus, 3);
      expect(s.daysToProduct, 27);
    });

    test('streak 6 belum klaim: hari ini bonus +4', () {
      final CheckInViewState s = _state(6);
      expect(s.todayIsBonus, isTrue);
      expect(s.todayKelopak, 4);
      expect(s.daysToBonus, 0);
    });

    test('streak 7 sudah klaim: strip penuh, bonus berikut 7 hari lagi', () {
      final CheckInViewState s = _state(7, claimed: true);
      expect(s.weekFilled, 7);
      expect(s.monthDay, 7);
      expect(s.todayIsBonus, isTrue);
      expect(s.daysToBonus, 7);
    });

    test('streak 29 belum klaim: hari ini produk gratis', () {
      final CheckInViewState s = _state(29);
      expect(s.monthDay, 29);
      expect(s.todayGrantsProduct, isTrue);
      expect(s.todayKelopak, 1);
      expect(s.daysToProduct, 1);
    });

    test('streak 30 sudah klaim: kisi penuh, strip di hari ke-2', () {
      final CheckInViewState s = _state(30, claimed: true);
      expect(s.monthDay, 30);
      expect(s.daysToProduct, 0);
      expect(s.weekFilled, 2);
    });

    test('streak 31 belum klaim: siklus kedua mulai dari hari 30', () {
      final CheckInViewState s = _state(31);
      expect(s.monthDay, 1);
      expect(s.weekFilled, 3);
      expect(s.todayStreakDay, 32);
      expect(s.monthCycleStart, 30);
    });

    test('streak 34 belum klaim: bonus jatuh di hari streak 35', () {
      final CheckInViewState s = _state(34);
      expect(s.todayIsBonus, isTrue);
      expect(s.monthDay, 4);
      expect(s.monthCycleStart, 30);
    });

    test('streak 0: semua kosong, hari pertama', () {
      final CheckInViewState s = _state(0);
      expect(s.weekFilled, 0);
      expect(s.monthDay, 0);
      expect(s.todayStreakDay, 1);
      expect(s.daysToBonus, 6);
      expect(s.daysToProduct, 30);
    });
  });

  group('CheckInViewState.fromProgress', () {
    test('klaim kemarin: streak hidup, hari ini belum', () {
      final CheckInViewState s = CheckInViewState.fromProgress(
        today: 100,
        lastClaimDay: 99,
        storedStreak: 5,
        balance: 12,
      );
      expect(s.streak, 5);
      expect(s.claimedToday, isFalse);
      expect(s.balance, 12);
    });

    test('klaim hari ini: sudah klaim', () {
      final CheckInViewState s = CheckInViewState.fromProgress(
        today: 100,
        lastClaimDay: 100,
        storedStreak: 5,
        balance: 12,
      );
      expect(s.streak, 5);
      expect(s.claimedToday, isTrue);
    });

    test('bolong satu hari: streak putus jadi 0', () {
      final CheckInViewState s = CheckInViewState.fromProgress(
        today: 100,
        lastClaimDay: 98,
        storedStreak: 5,
        balance: 12,
      );
      expect(s.streak, 0);
      expect(s.claimedToday, isFalse);
    });

    test('belum pernah klaim', () {
      final CheckInViewState s = CheckInViewState.fromProgress(
        today: 100,
        lastClaimDay: null,
        storedStreak: 0,
        balance: 0,
      );
      expect(s.streak, 0);
      expect(s.claimedToday, isFalse);
    });
  });

  group('CheckInViewState nilai', () {
    test('tamu: saldo 0, belum masuk, produk tetap terbawa', () {
      const CheckInRewardProduct product = CheckInRewardProduct(
        code: 'P1',
        name: 'Krim',
        image: AssetImage('x.webp'),
        price: 19900,
      );
      const CheckInViewState s = CheckInViewState.guest(
        rewardProduct: product,
        soundOn: true,
      );
      expect(s.signedIn, isFalse);
      expect(s.balance, 0);
      expect(s.streak, 0);
      expect(s.rewardProduct, product);
      expect(s.soundOn, isTrue);
    });

    test('copyWith mengganti sebagian, sisanya tetap', () {
      final CheckInViewState s = _state(3);
      final CheckInViewState t = s.copyWith(balance: 9, busy: true);
      expect(t.balance, 9);
      expect(t.busy, isTrue);
      expect(t.streak, 3);
      expect(t.signedIn, isTrue);
      expect(s.copyWith(), s);
    });

    test('kesamaan dan hashCode berdasarkan nilai', () {
      expect(_state(3), _state(3));
      expect(_state(3).hashCode, _state(3).hashCode);
      expect(_state(3), isNot(_state(4)));
      expect(_state(3), isNot(_state(3, claimed: true)));
    });

    test('streak negatif ditolak', () {
      expect(() => _state(-1), throwsAssertionError);
    });

    test('CheckInRewardProduct dibandingkan per nilai', () {
      const AssetImage image = AssetImage('x.webp');
      const CheckInRewardProduct a = CheckInRewardProduct(
        code: 'P1',
        name: 'Krim',
        image: image,
        price: 19900,
        strikePrice: 25000,
      );
      const CheckInRewardProduct b = CheckInRewardProduct(
        code: 'P1',
        name: 'Krim',
        image: image,
        price: 19900,
        strikePrice: 25000,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const CheckInRewardProduct(
            code: 'P2',
            name: 'Krim',
            image: image,
            price: 19900,
          ),
        ),
      );
    });
  });
}
