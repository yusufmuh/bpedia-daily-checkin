import 'check_in_view.dart';

/// `10000` menjadi `Rp10.000`.
String formatRupiah(int amount) {
  final String digits = amount.abs().toString();
  final StringBuffer out = StringBuffer(amount < 0 ? '-Rp' : 'Rp');
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Sisa waktu sebagai `05:12:33` (jam:menit:detik). Negatif dianggap nol.
String countdownClock(Duration left) {
  final int seconds = left.isNegative ? 0 : left.inSeconds;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:'
      '${two(seconds % 60)}';
}

/// Sisa waktu untuk pembaca layar: `5 jam 12 menit`, `12 menit`, atau
/// `kurang dari 1 menit`.
String countdownSpoken(Duration left) {
  final int minutes = left.isNegative ? 0 : left.inMinutes;
  if (minutes < 1) return 'kurang dari 1 menit';
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  if (hours == 0) return '$rest menit';
  if (rest == 0) return '$hours jam';
  return '$hours jam $rest menit';
}

/// Kalimat streak di bawah strip 7 hari.
String streakMessage(CheckInViewState state) {
  if (!state.signedIn) {
    return 'Masuk dulu, lalu klaim Kelopak pertamamu, Babes.';
  }
  if (state.streak == 0) {
    return 'Mulai streak hari ini. Hari ke-7 dapat bonus +3 Kelopak.';
  }
  final String streak = 'Streak ${state.streak} hari';
  if (!state.claimedToday) {
    if (state.todayGrantsProduct) {
      return '$streak · hari ini produk gratismu siap diklaim, Babes';
    }
    if (state.todayIsBonus) {
      return '$streak · hari ini bonus +3 Kelopak menunggumu';
    }
    return '$streak · jangan sampai terlewat ya, Babes';
  }
  if (state.todayIsBonus) return '$streak · bonus +3 Kelopak sudah masuk';
  return '$streak · ${state.daysToBonus} hari lagi menuju bonus +3 Kelopak';
}

/// Label ubin strip 7 hari untuk pembaca layar.
///
/// [day] 1..7, [filled] jumlah ubin terisi, [claimedToday] status hari ini.
String weekTileSemantics({
  required int day,
  required int filled,
  required bool claimedToday,
}) {
  final String status;
  if (day <= filled) {
    status = 'sudah check-in';
  } else if (day == filled + 1 && !claimedToday) {
    status = 'hari ini, belum check-in';
  } else {
    status = 'belum';
  }
  return 'Hari $day, $status${day == 7 ? ', bonus 3 Kelopak' : ''}';
}
