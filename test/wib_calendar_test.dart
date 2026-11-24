import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wibDayOf', () {
    test('tengah malam WIB = 17.00 UTC hari sebelumnya', () {
      final int before = wibDayOf(DateTime.utc(2026, 11, 23, 16, 59, 59));
      final int after = wibDayOf(DateTime.utc(2026, 11, 23, 17));
      expect(after - before, 1);
      expect(wibDateOf(before), DateTime.utc(2026, 11, 23));
      expect(wibDateOf(after), DateTime.utc(2026, 11, 24));
    });

    test('batas milidetik terakhir sebelum 00.00 WIB', () {
      final int lastMillis = wibDayOf(
        DateTime.utc(2026, 11, 23, 16, 59, 59, 999),
      );
      expect(lastMillis, wibDayOf(DateTime.utc(2026, 11, 23, 17)) - 1);
    });

    test('24 November 2026 WIB adalah hari ke-20781', () {
      expect(wibDayOf(DateTime.utc(2026, 11, 23, 17)), 20781);
      expect(wibDayOf(DateTime.utc(2026, 11, 24, 16, 59, 59)), 20781);
    });

    test('zona waktu objek DateTime tidak berpengaruh', () {
      final DateTime instant = DateTime.utc(2026, 11, 24, 3, 15);
      expect(wibDayOf(instant.toLocal()), wibDayOf(instant));
    });

    test('hari 0 dimulai 1 Januari 1970 00.00 WIB', () {
      expect(wibDayOf(DateTime.utc(1969, 12, 31, 17)), 0);
      expect(wibDayOf(DateTime.utc(1970, 1, 1, 16, 59, 59)), 0);
    });

    test('sebelum epoch dibulatkan ke bawah', () {
      expect(wibDayOf(DateTime.utc(1969, 12, 31, 16, 59, 59)), -1);
      expect(wibDayOf(DateTime.utc(1969, 12, 30, 17)), -1);
      expect(wibDayOf(DateTime.utc(1969, 12, 30, 16, 59, 59)), -2);
    });
  });

  group('wibWeekdayOf', () {
    test('Sabtu 28 November 2026 pukul 10.00 WIB = 6', () {
      expect(wibWeekdayOf(wibDayOf(DateTime.utc(2026, 11, 28, 3))), 6);
      expect(
        wibWeekdayOf(wibDayOf(DateTime.utc(2026, 11, 28, 3))),
        DateTime.saturday,
      );
    });

    test('Sabtu berakhir pukul 23.59 WIB, lalu Minggu', () {
      expect(wibWeekdayOf(wibDayOf(DateTime.utc(2026, 11, 28, 16, 59))), 6);
      expect(wibWeekdayOf(wibDayOf(DateTime.utc(2026, 11, 28, 17))), 7);
    });

    test('hari 0 adalah Kamis, hari -1 Rabu', () {
      expect(wibWeekdayOf(0), DateTime.thursday);
      expect(wibWeekdayOf(-1), DateTime.wednesday);
    });

    test('selalu sama dengan DateTime.weekday tanggal WIB', () {
      for (int day = -400; day <= 21200; day += 13) {
        expect(wibWeekdayOf(day), wibDateOf(day).weekday, reason: 'hari $day');
      }
    });
  });

  group('wibDateOf', () {
    test('mengembalikan tengah malam UTC dari tanggal WIB', () {
      final DateTime date = wibDateOf(20781);
      expect(date.isUtc, isTrue);
      expect(date, DateTime.utc(2026, 11, 24));
    });

    test('pulang-pergi wibDayOf(wibDateOf(d)) == d', () {
      for (int day = -800; day <= 21500; day += 7) {
        expect(wibDayOf(wibDateOf(day)), day, reason: 'hari $day');
      }
    });

    test('pulang-pergi dari instan ke tanggal kalender WIB', () {
      final List<DateTime> instants = <DateTime>[
        DateTime.utc(2026, 11, 23, 16, 59, 59),
        DateTime.utc(2026, 11, 23, 17),
        DateTime.utc(2026, 12, 31, 17, 30),
        DateTime.utc(2028, 2, 28, 18),
        DateTime.utc(2028, 2, 29, 16, 59),
      ];
      for (final DateTime instant in instants) {
        final DateTime local = instant.add(const Duration(hours: 7));
        final DateTime date = wibDateOf(wibDayOf(instant));
        expect(
          <int>[date.year, date.month, date.day],
          <int>[local.year, local.month, local.day],
          reason: '$instant',
        );
      }
    });
  });
}
