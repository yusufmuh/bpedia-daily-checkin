import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ledger of a simulated account, built only through [evaluateCheckIn].
final class _Account {
  int? lastClaimDay;
  int streak = 0;
  int balance = 0;
  int products = 0;

  CheckInAward? claim(int today) {
    final CheckInAward? award = evaluateCheckIn(
      today: today,
      lastClaimDay: lastClaimDay,
      streak: streak,
    );
    if (award == null) return null;
    lastClaimDay = today;
    streak = award.streak;
    balance += award.totalKelopak;
    if (award.productEntitled) products++;
    return award;
  }
}

const int _start = 20781;

void main() {
  group('CheckInRules', () {
    test('angka aturan sesuai kontrak', () {
      expect(CheckInRules.dailyKelopak, 1);
      expect(CheckInRules.bonusEvery, 7);
      expect(CheckInRules.bonusKelopak, 3);
      expect(CheckInRules.productEvery, 30);
    });
  });

  group('CheckInAward', () {
    test('totalKelopak = harian + bonus', () {
      const CheckInAward award = CheckInAward(
        streak: 7,
        dailyKelopak: 1,
        bonusKelopak: 3,
        productEntitled: false,
      );
      expect(award.totalKelopak, 4);
    });

    test('kesetaraan nilai', () {
      const CheckInAward a = CheckInAward(
        streak: 30,
        dailyKelopak: 1,
        bonusKelopak: 0,
        productEntitled: true,
      );
      const CheckInAward b = CheckInAward(
        streak: 30,
        dailyKelopak: 1,
        bonusKelopak: 0,
        productEntitled: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const CheckInAward(
            streak: 30,
            dailyKelopak: 1,
            bonusKelopak: 0,
            productEntitled: false,
          ),
        ),
      );
    });
  });

  group('evaluateCheckIn: akumulasi beruntun', () {
    test('hari 1..35: total kumulatif sesuai tabel', () {
      final _Account account = _Account();
      const Map<int, int> expectedTotal = <int, int>{
        1: 1,
        2: 2,
        6: 6,
        7: 10,
        8: 11,
        13: 16,
        14: 20,
        20: 26,
        21: 30,
        27: 36,
        28: 40,
        29: 41,
        30: 42,
        31: 43,
        34: 46,
        35: 50,
      };
      for (int day = 1; day <= 35; day++) {
        final CheckInAward? award = account.claim(_start + day - 1);
        expect(award, isNotNull, reason: 'hari $day');
        expect(award!.streak, day);
        expect(award.dailyKelopak, 1);
        expect(award.bonusKelopak, day % 7 == 0 ? 3 : 0, reason: 'hari $day');
        expect(award.productEntitled, day == 30, reason: 'hari $day');
        final int? total = expectedTotal[day];
        if (total != null) {
          expect(account.balance, total, reason: 'total hari $day');
        }
      }
      expect(account.products, 1);
    });

    test('7 hari pertama = 10 Kelopak (Rp1.000)', () {
      final _Account account = _Account();
      for (int day = 0; day < 7; day++) {
        account.claim(_start + day);
      }
      expect(account.balance, 10);
      expect(account.balance * 100, 1000);
    });

    test('hari ke-30 = 42 Kelopak dan 1 hak produk', () {
      final _Account account = _Account();
      CheckInAward? last;
      for (int day = 0; day < 30; day++) {
        last = account.claim(_start + day);
      }
      expect(last!.streak, 30);
      expect(last.productEntitled, isTrue);
      expect(last.totalKelopak, 1);
      expect(account.balance, 42);
      expect(account.products, 1);
    });

    test('hari ke-60 = hak produk kedua, 84 Kelopak', () {
      final _Account account = _Account();
      final List<int> productDays = <int>[];
      for (int day = 1; day <= 60; day++) {
        if (account.claim(_start + day - 1)!.productEntitled) {
          productDays.add(day);
        }
      }
      expect(productDays, <int>[30, 60]);
      expect(account.products, 2);
      expect(account.balance, 84);
    });

    test('hari ke-35 dan ke-70 dapat bonus, ke-90 dapat produk ketiga', () {
      final _Account account = _Account();
      final Map<int, CheckInAward> byDay = <int, CheckInAward>{};
      for (int day = 1; day <= 90; day++) {
        byDay[day] = account.claim(_start + day - 1)!;
      }
      expect(byDay[35]!.bonusKelopak, 3);
      expect(byDay[70]!.bonusKelopak, 3);
      expect(byDay[70]!.productEntitled, isFalse);
      expect(byDay[90]!.productEntitled, isTrue);
      expect(account.products, 3);
      expect(account.balance, 90 + 12 * 3);
    });
  });

  group('evaluateCheckIn: bolong', () {
    test('bolong 1 tanggal: rentetan kembali ke 1, saldo lama aman', () {
      final _Account account = _Account();
      for (int day = 0; day < 5; day++) {
        account.claim(_start + day);
      }
      expect(account.streak, 5);
      expect(account.balance, 5);

      final CheckInAward award = account.claim(_start + 6)!;
      expect(award.streak, 1);
      expect(award.totalKelopak, 1);
      expect(award.bonusKelopak, 0);
      expect(account.balance, 6);
    });

    test('bolong sebelum hari ke-7: tidak ada bonus di tanggal ke-7', () {
      final _Account account = _Account();
      for (int day = 0; day < 6; day++) {
        account.claim(_start + day);
      }
      final CheckInAward award = account.claim(_start + 7)!;
      expect(award.streak, 1);
      expect(award.bonusKelopak, 0);
      expect(account.balance, 7);
    });

    test('bolong setelah hari ke-29: tidak ada produk, hak lama aman', () {
      final _Account account = _Account();
      for (int day = 0; day < 30; day++) {
        account.claim(_start + day);
      }
      for (int day = 31; day < 60; day++) {
        account.claim(_start + day);
      }
      expect(account.streak, 29);
      expect(account.products, 1);
      final CheckInAward award = account.claim(_start + 61)!;
      expect(award.streak, 1);
      expect(award.productEntitled, isFalse);
      expect(account.products, 1);
    });

    test('jeda panjang tetap mulai dari 1', () {
      final CheckInAward award = evaluateCheckIn(
        today: _start + 400,
        lastClaimDay: _start,
        streak: 29,
      )!;
      expect(award.streak, 1);
      expect(award.productEntitled, isFalse);
    });
  });

  group('evaluateCheckIn: satu kali per tanggal', () {
    test('klaim pertama memberi rentetan 1 dan 1 Kelopak', () {
      expect(
        evaluateCheckIn(today: _start, lastClaimDay: null, streak: 0),
        const CheckInAward(
          streak: 1,
          dailyKelopak: 1,
          bonusKelopak: 0,
          productEntitled: false,
        ),
      );
    });

    test('ulang di tanggal yang sama mengembalikan null', () {
      final _Account account = _Account();
      expect(account.claim(_start), isNotNull);
      expect(account.claim(_start), isNull);
      expect(account.balance, 1);
      expect(
        evaluateCheckIn(today: _start, lastClaimDay: _start, streak: 1),
        isNull,
      );
    });

    test('lastClaimDay setelah today (jam mundur) mengembalikan null', () {
      expect(
        evaluateCheckIn(today: _start, lastClaimDay: _start + 1, streak: 4),
        isNull,
      );
      expect(
        evaluateCheckIn(today: _start, lastClaimDay: _start + 30, streak: 4),
        isNull,
      );
    });

    test('rentetan tersimpan rusak tidak menghasilkan rentetan <= 0', () {
      expect(
        evaluateCheckIn(
          today: _start + 1,
          lastClaimDay: _start,
          streak: -5,
        )!.streak,
        1,
      );
      expect(
        evaluateCheckIn(
          today: _start + 1,
          lastClaimDay: _start,
          streak: 0,
        )!.streak,
        1,
      );
    });
  });

  group('liveStreak', () {
    test('belum pernah klaim = 0', () {
      expect(liveStreak(today: _start, lastClaimDay: null, streak: 0), 0);
    });

    test('klaim terakhir hari ini = rentetan tersimpan', () {
      expect(liveStreak(today: _start, lastClaimDay: _start, streak: 9), 9);
    });

    test('klaim terakhir kemarin = rentetan tersimpan', () {
      expect(liveStreak(today: _start, lastClaimDay: _start - 1, streak: 9), 9);
    });

    test('setelah bolong = 0', () {
      expect(liveStreak(today: _start, lastClaimDay: _start - 2, streak: 9), 0);
      expect(
        liveStreak(today: _start, lastClaimDay: _start - 40, streak: 29),
        0,
      );
    });

    test('jam mundur tidak memutus rentetan', () {
      expect(liveStreak(today: _start, lastClaimDay: _start + 1, streak: 9), 9);
    });

    test('rentetan negatif dianggap 0', () {
      expect(liveStreak(today: _start, lastClaimDay: _start, streak: -2), 0);
    });
  });

  group('isClaimedOn', () {
    test('tabel', () {
      expect(isClaimedOn(today: _start, lastClaimDay: null), isFalse);
      expect(isClaimedOn(today: _start, lastClaimDay: _start - 1), isFalse);
      expect(isClaimedOn(today: _start, lastClaimDay: _start - 9), isFalse);
      expect(isClaimedOn(today: _start, lastClaimDay: _start), isTrue);
      expect(isClaimedOn(today: _start, lastClaimDay: _start + 1), isTrue);
    });

    test('sejalan dengan evaluateCheckIn', () {
      for (final int? last in <int?>[
        null,
        _start - 3,
        _start - 1,
        _start,
        _start + 2,
      ]) {
        expect(
          isClaimedOn(today: _start, lastClaimDay: last),
          evaluateCheckIn(today: _start, lastClaimDay: last, streak: 3) == null,
          reason: 'lastClaimDay $last',
        );
      }
    });
  });

  group('filledInWeek', () {
    const Map<int, (int, int)> table = <int, (int, int)>{
      0: (0, 0),
      1: (1, 1),
      6: (6, 6),
      7: (7, 0),
      8: (1, 1),
      13: (6, 6),
      14: (7, 0),
      15: (1, 1),
      29: (1, 1),
      30: (2, 2),
    };

    for (final MapEntry<int, (int, int)> row in table.entries) {
      test(
        'rentetan ${row.key}: sudah ${row.value.$1}, belum ${row.value.$2}',
        () {
          expect(
            filledInWeek(liveStreak: row.key, claimedToday: true),
            row.value.$1,
          );
          expect(
            filledInWeek(liveStreak: row.key, claimedToday: false),
            row.value.$2,
          );
        },
      );
    }

    test('nilai negatif = 0', () {
      expect(filledInWeek(liveStreak: -3, claimedToday: true), 0);
      expect(filledInWeek(liveStreak: -3, claimedToday: false), 0);
    });

    test('selalu 0..7 dan bukan 7 bila belum check-in', () {
      for (int streak = 0; streak <= 120; streak++) {
        final int claimed = filledInWeek(
          liveStreak: streak,
          claimedToday: true,
        );
        final int open = filledInWeek(liveStreak: streak, claimedToday: false);
        expect(claimed, inInclusiveRange(0, 7));
        expect(open, inInclusiveRange(0, 6));
      }
    });
  });

  group('dayInMonthCycle', () {
    const Map<int, (int, int)> table = <int, (int, int)>{
      0: (0, 0),
      1: (1, 1),
      6: (6, 6),
      7: (7, 7),
      8: (8, 8),
      13: (13, 13),
      14: (14, 14),
      29: (29, 29),
      30: (30, 0),
      31: (1, 1),
      60: (30, 0),
      61: (1, 1),
    };

    for (final MapEntry<int, (int, int)> row in table.entries) {
      test(
        'rentetan ${row.key}: sudah ${row.value.$1}, belum ${row.value.$2}',
        () {
          expect(
            dayInMonthCycle(liveStreak: row.key, claimedToday: true),
            row.value.$1,
          );
          expect(
            dayInMonthCycle(liveStreak: row.key, claimedToday: false),
            row.value.$2,
          );
        },
      );
    }

    test('nilai negatif = 0', () {
      expect(dayInMonthCycle(liveStreak: -1, claimedToday: true), 0);
    });
  });

  group('alur harian ujung ke ujung', () {
    test('tampilan mengikuti klaim, pergantian hari, dan bolong', () {
      final _Account account = _Account();
      int today = _start;

      ({int filled, int month, bool claimed}) view() {
        final bool claimed = isClaimedOn(
          today: today,
          lastClaimDay: account.lastClaimDay,
        );
        final int live = liveStreak(
          today: today,
          lastClaimDay: account.lastClaimDay,
          streak: account.streak,
        );
        return (
          filled: filledInWeek(liveStreak: live, claimedToday: claimed),
          month: dayInMonthCycle(liveStreak: live, claimedToday: claimed),
          claimed: claimed,
        );
      }

      expect(view(), (filled: 0, month: 0, claimed: false));
      account.claim(today);
      expect(view(), (filled: 1, month: 1, claimed: true));
      for (int i = 0; i < 6; i++) {
        today++;
        account.claim(today);
      }
      expect(view(), (filled: 7, month: 7, claimed: true));
      today++;
      expect(view(), (filled: 0, month: 7, claimed: false));
      today += 2;
      expect(view(), (filled: 0, month: 0, claimed: false));
      account.claim(today);
      expect(view(), (filled: 1, month: 1, claimed: true));
      expect(account.balance, 11);
    });
  });
}
