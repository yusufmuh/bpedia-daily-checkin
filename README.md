# daily_checkin · Check-in Harian (Bpedia Preview)

Paket Flutter untuk Check-in Harian Bpedia: engine murni berbasis tanggal WIB dan tiga widget bertema **Kebun Bipy**. Aturan dan kontrak lengkap ada di [PRD.md](PRD.md); kontrak lintas modul di `bpedia-kelopak-hub/docs/SPEC-CONTRACT.md`.

Aturan singkat: +1 Kelopak per tanggal WIB (1 Kelopak = Rp100), +3 bonus di hari ke-7, 14, 21, … beruntun, 1 hak produk gratis di hari ke-30, 60, … beruntun. Bolong satu tanggal = rentetan mulai dari 1; saldo dan hak lama tetap.

## Isi paket

| Simbol | Jenis | Fungsi |
|---|---|---|
| `CheckInRules` | konstanta | `dailyKelopak` 1, `bonusEvery` 7, `bonusKelopak` 3, `productEvery` 30 |
| `wibDayOf(DateTime)` | fungsi | hari WIB sejak 1 Jan 1970 (pergantian 00.00 WIB) |
| `wibWeekdayOf(int)` | fungsi | 1 = Senin … 6 = Sabtu, 7 = Minggu |
| `wibDateOf(int)` | fungsi | `DateTime` UTC berisi tanggal kalender WIB |
| `CheckInAward` | kelas nilai | `streak`, `dailyKelopak`, `bonusKelopak`, `productEntitled`, `totalKelopak` |
| `evaluateCheckIn(...)` | fungsi | hasil klaim, atau `null` bila tanggal sudah diklaim / jam mundur |
| `liveStreak(...)` | fungsi | rentetan yang masih hidup hari ini (0 bila bolong) |
| `isClaimedOn(...)` | fungsi | apakah hari ini sudah tidak bisa diklaim |
| `filledInWeek(...)` | fungsi | jumlah tulip mekar di jejak 7 hari (0..7) |
| `dayInMonthCycle(...)` | fungsi | progres menuju produk gratis (0..30) |
| `CheckInButtonState` | enum | `ready`, `claimed` |
| `CheckInWeekTrack` | widget | 7 slot tulip; slot hari ini berdenyut; slot 7 kado + "+3" |
| `CheckInMonthProgress` | widget | lintasan 30 hari, penanda 7/14/21/28, hadiah di ujung |
| `CheckInClaimButton` | widget | "Ambil 1 Kelopak" / "Sudah check-in hari ini" + petunjuk |

Engine tidak punya efek samping: host yang menyimpan `lastClaimDay`, `streak`, dan ledger.

## Pasang

Git (aplikasi di luar workspace; kunci `ref` ke commit tertentu untuk build rilis):

```yaml
dependencies:
  daily_checkin:
    git:
      url: https://github.com/yusufmuh/bpedia-daily-checkin.git
      ref: main
```

Workspace lokal (repo bersebelahan dengan `bpedia-kelopak-hub`):

```yaml
dependencies:
  daily_checkin:
    path: ../bpedia-daily-checkin
```

Butuh Flutter 3.41+ / Dart 3.11+. Tanpa dependensi pihak ketiga.

## Pakai

```dart
import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';

/// Bagian layar Check-in Harian. `today` = wibDayOf(jam.now()) + offset demo.
class CheckInSection extends StatelessWidget {
  const CheckInSection({
    super.key,
    required this.today,
    required this.lastClaimDay,
    required this.streak,
    required this.onClaim,
  });

  final int today;
  final int? lastClaimDay;
  final int streak;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final bool claimed = isClaimedOn(today: today, lastClaimDay: lastClaimDay);
    final int live = liveStreak(
      today: today,
      lastClaimDay: lastClaimDay,
      streak: streak,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CheckInWeekTrack(
          filled: filledInWeek(liveStreak: live, claimedToday: claimed),
          claimedToday: claimed,
          currencyIcon: Image.asset('assets/kelopak.png'),
          bonusIcon: Image.asset('assets/hadiah_bonus.png'),
        ),
        const SizedBox(height: 16),
        CheckInClaimButton(
          state: claimed ? CheckInButtonState.claimed : CheckInButtonState.ready,
          onPressed: onClaim,
          claimedHint: 'Kembali besok mulai 00.00 WIB untuk Hari ke-${live + 1}',
        ),
        const SizedBox(height: 24),
        CheckInMonthProgress(
          day: dayInMonthCycle(liveStreak: live, claimedToday: claimed),
          rewardImage: Image.asset('assets/produk_gratis.png'),
        ),
      ],
    );
  }
}
```

Nama aset di atas milik host; ganti dengan aset aplikasi Anda. Saat tombol diketuk:

```dart
final CheckInAward? award = evaluateCheckIn(
  today: today,
  lastClaimDay: lastClaimDay,
  streak: streak,
);
if (award != null) {
  // Simpan lastClaimDay = today dan streak = award.streak.
  // Ledger: +award.dailyKelopak, +award.bonusKelopak bila > 0,
  // dan satu hak produk bila award.productEntitled.
}
```

## Slot tema

Widget hanya membaca `Theme.of(context)`; tidak ada warna tetap.

| Widget | ColorScheme | TextTheme | Slot gambar |
|---|---|---|---|
| `CheckInWeekTrack` | `primary` (garis hari ini, lencana, kelopak), `onPrimary`, `primaryContainer` (slot sudah), `secondary` (kelopak belakang, label hari ini), `surfaceContainerLowest` (slot hari ini), `surfaceContainer` (slot belum), `tertiaryContainer` + `onTertiaryContainer` (slot 7), `tertiary` + `onTertiary` (pil "+3"), `onSurface`, `onSurfaceVariant` (label, tangkai) | `labelSmall` | `currencyIcon` 16 dp, `bonusIcon` 26 dp (cadangan `Icons.card_giftcard`) |
| `CheckInMonthProgress` | `primary` (isi, ikon hadiah), `onPrimary` (titik terlewati), `secondaryContainer` (lintasan), `outline` (titik berikutnya), `secondary` (teks 30/30), `tertiaryContainer` + `onTertiaryContainer` (hadiah tercapai), `onSurface`, `onSurfaceVariant` | `titleSmall`, `labelLarge` | `rewardImage` 28 dp (cadangan `Icons.redeem`) |
| `CheckInClaimButton` | gaya `FilledButton` tema (siap); `primaryContainer`, `onPrimaryContainer`, `secondary` (sudah); `onSurfaceVariant` (petunjuk) | `bodySmall` + gaya tombol tema | — |

`Icon` di slot gambar otomatis berukuran sesuai slot; `Image` dipaskan ke kotak slot.

## Aksesibilitas & gerak

- Tiap slot jejak punya label sendiri: "Hari 4, hari ini, belum check-in", "Hari 7, belum, bonus 3 Kelopak".
- Progres: label "Progres produk gratis", nilai "12 dari 30 hari".
- Teks 200% di layar 360 dp tanpa overflow.
- Slot hari ini berdenyut 1,0 sampai 1,06 (1,2 dtk) dan berhenti bila `MediaQuery.disableAnimationsOf(context)` true.

Catatan test host: denyut berjalan terus selama slot hari ini tampil, jadi `pumpAndSettle()` akan timeout. Bungkus dengan `MediaQuery(data: ...copyWith(disableAnimations: true))` atau pakai `pump(Duration)`.

## Server

`server/checkin.php` mencerminkan aturan yang sama (`CheckInEngine`) dan menyediakan `claimDay(array &$state, int $today): string` untuk router demo hub.

## Perintah

```bash
flutter pub get
flutter analyze
flutter test
php -l server/checkin.php
php server/checkin.php   # swa-uji aturan server
```
