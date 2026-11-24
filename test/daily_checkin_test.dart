import 'package:flutter_test/flutter_test.dart';
import 'package:daily_checkin/daily_checkin.dart';

void main() {
  group('PRD 1 - Check-in Harian Logic Tests', () {
    test('Klaim pertama memberi streak 1 dan 1 Kelopak', () {
      final res = evaluateCheckIn(today: 100, last: null, streak: 0);
      expect(res, isNotNull);
      expect(res!.streak, 1);
      expect(res.kelopak, 1);
      expect(res.product, isFalse);
    });

    test('Klaim berturut-turut hari ke-2 memberi streak 2 dan 1 Kelopak', () {
      final res = evaluateCheckIn(today: 101, last: 100, streak: 1);
      expect(res, isNotNull);
      expect(res!.streak, 2);
      expect(res.kelopak, 1);
    });

    test('Klaim di hari yang sama ditolak (kembali null)', () {
      final res = evaluateCheckIn(today: 100, last: 100, streak: 1);
      expect(res, isNull);
    });

    test('Klaim hari ke-7 (strike 1 minggu) memberi 1 harian + 3 bonus = 4 Kelopak', () {
      final res = evaluateCheckIn(today: 107, last: 106, streak: 6);
      expect(res, isNotNull);
      expect(res!.streak, 7);
      expect(res.kelopak, 4); // 1 + 3 bonus
      expect(res.product, isFalse);
    });

    test('Akumulasi 7 hari menghasilkan tepat 10 Kelopak (Rp1.000)', () {
      int totalKelopak = 0;
      int streak = 0;
      int? lastDay;

      for (int i = 1; i <= 7; i++) {
        final award = evaluateCheckIn(today: i, last: lastDay, streak: streak);
        expect(award, isNotNull);
        totalKelopak += award!.kelopak;
        streak = award.streak;
        lastDay = i;
      }

      expect(streak, 7);
      expect(totalKelopak, 10); // 6x1 + 1x4 = 10 Kelopak = Rp1.000
    });

    test('Bolong 1 hari mereset streak kembali ke 1', () {
      // Terakhir klaim hari 100, sekarang hari 102 (hari 101 bolong)
      final res = evaluateCheckIn(today: 102, last: 100, streak: 5);
      expect(res, isNotNull);
      expect(res!.streak, 1);
      expect(res.kelopak, 1);
    });

    test('Klaim hari ke-30 berturut-turut menerbitkan 1 hak produk gratis', () {
      final res = evaluateCheckIn(today: 130, last: 129, streak: 29);
      expect(res, isNotNull);
      expect(res!.streak, 30);
      expect(res.product, isTrue);
    });
  });
}
