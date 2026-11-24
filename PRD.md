# PRD 01 · Check-in Harian (Bpedia Preview)

**Versi 2.0 · 24 November 2026 · Owner: Muhammad Yusuf (Bpedia)**
Paket Flutter `daily_checkin` (repo `bpedia-daily-checkin`) dan cermin aturan server `server/checkin.php`.

Acuan yang lebih tinggi (bila berbeda, acuan ini yang berlaku):
- `../bpedia-kelopak-hub/docs/SPEC-CONTRACT.md` · aturan bisnis §1 dan API publik §2
- `../bpedia-kelopak-hub/docs/SPEC-UIUX.md` · prinsip UX, layar 3.6 Check-in Harian, umpan balik §4, copy §6
- `../bpedia-kelopak-hub/PRD.md` · PRD pusat

---

## 1. Tujuan

1. Memberi pembeli alasan membuka Bpedia setiap hari dengan **satu ketukan**: "Ambil 1 Kelopak".
2. **Satu tempat check-in saja.** Kebun Bipy dari mockup lama dilebur ke Check-in Harian sebagai visual: 7 tulip yang mekar per hari check-in. Tidak ada tombol check-in kedua.
3. Pengguna selalu tahu: hari ke berapa rentetannya, apa yang didapat hari ini, kapan bonus +3 dan produk gratis, dan kapan bisa kembali.

## 2. Aturan bisnis (wajib persis)

| Aturan | Nilai |
|---|---|
| Nilai | 1 Kelopak = Rp100. Bilangan bulat, saldo tidak pernah negatif. Saldo = jumlah ledger. |
| Klaim harian | +1 Kelopak per **tanggal WIB** (UTC+7), maksimal satu klaim per tanggal. |
| Bonus mingguan | Hari ke-7, 14, 21, … beruntun: **+3 Kelopak** di atas +1 harian (total 7 hari = 10 Kelopak = Rp1.000). |
| Produk gratis | Hari ke-30, 60, 90, … beruntun: **1 hak produk gratis**. |
| Bolong | Lewat satu tanggal tanpa check-in: rentetan mulai lagi dari Hari 1. Saldo Kelopak dan hak produk yang sudah didapat **tidak hilang**. |
| Pergantian hari | Tepat 00.00 WIB. Jam perangkat tidak menentukan tanggal di produksi (server); di Mode Demo tanggal = `wibDayOf(now) + demoOffsetDays`. |
| Jam mundur | Tanggal yang tidak lebih besar dari tanggal klaim terakhir ditolak (tidak ada klaim ganda). |

Contoh perolehan beruntun tanpa bolong:

| Hari beruntun | Diterima hari itu | Total kumulatif | Setara |
|---:|---|---:|---:|
| 1 | +1 | 1 | Rp100 |
| 6 | +1 | 6 | Rp600 |
| 7 | +1 + bonus 3 | 10 | Rp1.000 |
| 14 | +1 + bonus 3 | 20 | Rp2.000 |
| 21 | +1 + bonus 3 | 30 | Rp3.000 |
| 28 | +1 + bonus 3 | 40 | Rp4.000 |
| 30 | +1 + 1 produk gratis | 42 | Rp4.200 + 1 produk |
| 35 | +1 + bonus 3 | 50 | Rp5.000 + 1 produk |
| 60 | +1 + 1 produk gratis | 84 | Rp8.400 + 2 produk |

Beban maksimal per pengguna per 30 hari: 42 Kelopak (Rp4.200) + 1 produk promosi.

## 3. Kalender WIB

| Fungsi | Rumus |
|---|---|
| Hari WIB | `wibDay = floor((utcMillis + 7×3600×1000) / 86400000)`; hari 0 = Kamis 1 Januari 1970 |
| Hari dalam minggu | `((wibDay + 3) mod 7) + 1` → 1 = Senin … 6 = Sabtu, 7 = Minggu |
| Tanggal kalender | `DateTime.utc(1970).add(Duration(days: wibDay))`, baca tahun/bulan/tanggal |

Contoh: 23 Nov 2026 16.59.59 UTC = hari 20780 (Senin 23 Nov WIB); 23 Nov 2026 17.00.00 UTC = hari 20781 (Selasa 24 Nov WIB). 28 Nov 2026 10.00 WIB = Sabtu (6). Instan sebelum 1970 dibulatkan ke bawah (hari -1 = Rabu 31 Des 1969).

## 4. Pengalaman pengguna

### 4.1 Letak & alur (dirakit host `kelopak_hub`)

- **Beranda** · kartu Kelopak hari ini: belum check-in → token + saldo + tombol "Ambil 1 Kelopak" langsung; sudah → "Sudah check-in · Hari ke-4 beruntun" + "Lihat hadiah". Tanpa pop-up saat app dibuka.
- **Hadiah** · kartu Check-in Harian: jejak 7 hari mini + status.
- **Layar Check-in Harian** (urutan atas ke bawah): hero Bipy + "Hari ke-3 beruntun" → `CheckInWeekTrack` → `CheckInClaimButton` → `CheckInMonthProgress` → tombol "Cara kerja" (bottom sheet berisi aturan §2 dan tabel contoh: hari 1 = 1, hari 7 = 10 total, hari 30 = 42 total + produk).
- Rentetan putus: peringatan lembut "Rentetanmu mulai lagi dari Hari 1. Kelopak yang sudah kamu kumpulkan tetap aman."

### 4.2 Komponen paket

**`CheckInWeekTrack` · Kebun Bipy.** Tujuh slot sama lebar dalam satu baris (masing-masing `Expanded`, ubin radius 16, rasio 4:5, lebar maks. 64 dp). Di bawah tiap ubin: "Hari N" (`labelSmall`, satu baris, mengecil bila sempit).

| Status slot | Tampilan | Label pembaca layar |
|---|---|---|
| Sudah check-in | isi `primaryContainer`, tulip mekar 3 kelopak (warna dari `primary`/`secondary`), lencana centang | "Hari N, sudah check-in" |
| Hari ini, belum check-in | garis `primary` 2 dp, kuncup tulip, token Kelopak 16 dp, berdenyut halus 1,0 sampai 1,06 tiap 1,2 dtk (diam bila animasi dimatikan) | "Hari N, hari ini, belum check-in" |
| Belum | isi `surfaceContainer`, kuncup pudar | "Hari N, belum" |
| Slot 7 | isi `tertiaryContainer`, ikon kado (`bonusIcon`, cadangan `Icons.card_giftcard`) + pil "+3"; setelah diklaim tulip mekar + pil "+3" | label status + ", bonus 3 Kelopak" |

Bila hari ke-7 sudah diklaim hari ini, ketujuh tulip mekar. Esoknya minggu baru dimulai dari slot 1.

**`CheckInMonthProgress`.** Baris "Menuju produk gratis" + "{day} dari 30 hari" (pindah baris bila sempit). Lintasan tinggi 10 dp berbentuk pil: isi `primary`, titik penanda di hari 7/14/21/28 (penuh bila terlewati), slot hadiah di ujung (`rewardImage` 28 dp, cadangan `Icons.redeem`, berlatar `tertiaryContainer` saat 30/30). Pembaca layar: label "Progres produk gratis", nilai "{day} dari 30 hari".

**`CheckInClaimButton`.** `FilledButton` selebar wadah, tinggi min. 52 dp, tanpa spinner.

| Status | Tampilan |
|---|---|
| `ready` | ikon bunga + "Ambil 1 Kelopak". `onPressed: null` = nonaktif sementara (host sedang menyimpan). |
| `claimed` | nonaktif, isi `primaryContainer`, ikon centang + "Sudah check-in hari ini"; di bawahnya `claimedHint` (`bodySmall`, `onSurfaceVariant`, rata tengah), mis. "Kembali besok mulai 00.00 WIB untuk Hari ke-4". |

### 4.3 Keadaan layar

| Keadaan | Jejak 7 hari | Progres bulanan | Tombol |
|---|---|---|---|
| Pengguna baru | slot 1 = hari ini | 0 dari 30 hari | Ambil 1 Kelopak |
| Rentetan 3, belum hari ini | 3 mekar, slot 4 = hari ini | 3 dari 30 hari | Ambil 1 Kelopak |
| Rentetan 7, sudah hari ini | 7 mekar | 7 dari 30 hari | Sudah check-in + petunjuk Hari ke-8 |
| Rentetan 7, keesokan harinya | slot 1 = hari ini | 7 dari 30 hari | Ambil 1 Kelopak |
| Bolong | slot 1 = hari ini | 0 dari 30 hari | Ambil 1 Kelopak + peringatan lembut |
| Rentetan 30, sudah hari ini | 2 mekar | 30 dari 30 hari | Sudah check-in |

### 4.4 Umpan balik setelah klaim (host)

| Peristiwa | Visual | Suara | Getar |
|---|---|---|---|
| Check-in biasa | ledakan kelopak kecil (maks. 900 ms) | `claim` | lightImpact |
| Bonus hari ke-7/14/… | ledakan + badge "+3" | `bonus` | mediumImpact |
| Produk gratis hari ke-30/60/… | konfeti kelopak + kado 3D | `win_product` | heavyImpact |

Lembar hasil yang bisa ditutup: "+1 Kelopak" / "+1 Kelopak + bonus 3 Kelopak" / "+ 1 produk gratis", lalu saldo baru ("12 Kelopak (Rp1.200)"). Semua animasi dilewati bila `MediaQuery.disableAnimationsOf(context)` true; suara mengikuti Akun > Suara & getar.

### 4.5 Copy

"Ambil 1 Kelopak" · "Sudah check-in hari ini" · "Kembali besok mulai 00.00 WIB untuk Hari ke-{n}" · "Hari ke-{n} beruntun" · "Menuju produk gratis" · "{day} dari 30 hari" · "1 Kelopak = Rp100". Sentence case, glosarium tunggal (Check-in Harian, Kelopak). Tidak memakai "Daily Sign In", "koin", atau glyph `≥ → ✓` (font brand tidak punya); pakai kata "min." atau ikon.

### 4.6 Aksesibilitas

- Setiap slot satu node semantics dengan label lengkap; teks "Hari N" tidak dibacakan dua kali.
- Target sentuh: tombol min. 52 dp; jejak dan progres tidak bisa diketuk.
- Teks 200% pada layar 360 × 740 dp tanpa overflow (label hari mengecil, pil "+3" dibatasi 130%, teks lain membungkus).
- Status selalu teks + ikon, bukan warna saja (lencana centang, kuncup vs tulip mekar, label).
- Kontras: label hari ini dan teks 30/30 memakai `secondary` (berry-700, 6,4:1 di pearl), bukan pink-600.
- Kurangi gerakan: denyut slot hari ini berhenti dan ubin kembali 100%.

## 5. API publik (`package:daily_checkin/daily_checkin.dart`)

```dart
abstract final class CheckInRules {
  static const int dailyKelopak = 1;
  static const int bonusEvery = 7;
  static const int bonusKelopak = 3;
  static const int productEvery = 30;
}
int wibDayOf(DateTime instant);
int wibWeekdayOf(int wibDay);   // 1..7
DateTime wibDateOf(int wibDay); // UTC DateTime = tanggal kalender WIB
final class CheckInAward {
  const CheckInAward({required this.streak, required this.dailyKelopak,
      required this.bonusKelopak, required this.productEntitled});
  final int streak;
  final int dailyKelopak;
  final int bonusKelopak;
  final bool productEntitled;
  int get totalKelopak;
}
CheckInAward? evaluateCheckIn({required int today, required int? lastClaimDay, required int streak});
int liveStreak({required int today, required int? lastClaimDay, required int streak});
bool isClaimedOn({required int today, required int? lastClaimDay});
int filledInWeek({required int liveStreak, required bool claimedToday});   // 0..7
int dayInMonthCycle({required int liveStreak, required bool claimedToday}); // 0..30
enum CheckInButtonState { ready, claimed }
class CheckInWeekTrack extends StatelessWidget
  ({required int filled, required bool claimedToday, required Widget currencyIcon, Widget? bonusIcon});
class CheckInMonthProgress extends StatelessWidget ({required int day, Widget? rewardImage});
class CheckInClaimButton extends StatelessWidget
  ({required CheckInButtonState state, required VoidCallback? onPressed, required String claimedHint});
```

| Simbol | Perilaku |
|---|---|
| `evaluateCheckIn` | `null` bila `today <= lastClaimDay` (sudah diklaim atau jam mundur). Rentetan lanjut hanya bila `lastClaimDay == today - 1`; selain itu mulai dari 1. Rentetan tersimpan negatif/0 dianggap 0. |
| `liveStreak` | Rentetan pada `today`: tetap bila klaim terakhir hari ini/kemarin (atau setelah jam mundur), 0 bila belum pernah klaim atau ada bolong. |
| `isClaimedOn` | `true` tepat ketika `evaluateCheckIn` akan mengembalikan `null`. |
| `filledInWeek` | Sudah hari ini: `(s - 1) % 7 + 1`; belum: `s % 7`; `s <= 0` → 0. Slot hari ini = indeks hasil (bila belum). |
| `dayInMonthCycle` | Sudah hari ini: `(s - 1) % 30 + 1`; belum: `s % 30`; `s <= 0` → 0. |
| `CheckInAward` | Nilai tak berubah dengan `==`/`hashCode`; `totalKelopak = dailyKelopak + bonusKelopak`. |

Widget hanya memakai `Theme.of(context)` (ColorScheme + TextTheme). Gambar datang dari slot host: `currencyIcon` 16 dp, `bonusIcon` 26 dp, `rewardImage` 28 dp. Ilustrasi tulip digambar `CustomPainter` dari warna tema.

## 6. Data & integrasi

- **Mode Demo (Bpedia Preview):** host menyimpan `lastClaimDay` dan `streak` di dokumen state lokal, mencatat ledger (+1, +3 bonus, hak produk) dan menghitung saldo dari ledger. Engine paket ini murni dan deterministik.
- **Produksi:** server memegang kebenaran (saldo, rentetan, tanggal WIB). Aturan identik di `server/checkin.php`. Rujukan kontrak PRD pusat §6: `POST /v1/checkin/claim` dengan `Idempotency-Key`; klaim kedua di tanggal yang sama tidak menambah saldo.

## 7. Server (`server/checkin.php`)

- `CheckInEngine::wibDayOf`, `wibWeekdayOf`, `wibDateOf`, `evaluate`, `liveStreak`, `isClaimedOn`, `filledInWeek`, `dayInMonthCycle` (cermin fungsi Dart).
- `claimDay(array &$state, int $today): string` · kompatibel dengan router demo hub (`server/index.php`): memperbarui `streak`, `lastDay`, `balance`, `products`; mengembalikan label riwayat ("+1 Kelopak + bonus 3 Kelopak · Hari ke-7"); melempar `DomainException` ("Kamu sudah check-in hari ini. Kembali besok mulai 00.00 WIB.") untuk klaim ganda.
- `php server/checkin.php` menjalankan swa-uji tabel yang sama dengan test Dart (54 cek). Di SAPI web tidak ada keluaran.

## 8. Uji penerimaan

| ID | Skenario | Hasil yang diharapkan | Test |
|---|---|---|---|
| AT-01 | Konstanta aturan | 1 / 7 / 3 / 30 | `check_in_engine_test.dart` |
| AT-02 | Klaim beruntun hari 1..35 | total hari 7 = 10, 14 = 20, 21 = 30, 28 = 40, 30 = 42 + hak produk, 35 = 50 | engine |
| AT-03 | Klaim beruntun sampai hari 60 dan 90 | hak produk di hari 30 dan 60 (total 84), produk ke-3 di hari 90 | engine |
| AT-04 | Bolong satu tanggal | rentetan kembali 1, +1 saja, total lama utuh; tidak ada bonus/produk karena posisi tanggal | engine |
| AT-05 | Klaim ulang di tanggal sama / jam mundur | `null`, saldo tidak berubah | engine |
| AT-06 | `liveStreak` | bolong = 0; klaim terakhir hari ini atau kemarin = rentetan | engine |
| AT-07 | `filledInWeek` & `dayInMonthCycle` | tabel rentetan 0, 1, 6, 7, 8, 13, 14 (sudah & belum), 29, 30, 31, 60 | engine |
| AT-08 | Kalender WIB | 16.59.59 UTC vs 17.00 UTC beda satu hari; 28 Nov 2026 = Sabtu; pulang-pergi tanggal; sebelum epoch | `wib_calendar_test.dart` |
| AT-09 | Semantics jejak 7 hari | label tepat per slot, termasuk ", bonus 3 Kelopak" | `check_in_widgets_test.dart` |
| AT-10 | Tombol | `ready` aktif + 1 kali panggilan; `claimed` nonaktif + petunjuk di bawah; min. 52 dp, lebar penuh, tanpa spinner | widget |
| AT-11 | Progres bulanan | label/nilai semantics, batas 0..30, gambar hadiah 28 dp atau `Icons.redeem` | widget |
| AT-12 | Denyut slot hari ini | skala 1,0 sampai 1,06; diam bila animasi dimatikan; tidak ada denyut setelah check-in | widget |
| AT-13 | Teks 200% di 360 × 740 dan 320 × 740, tema terang & gelap | tanpa overflow/exception | widget |
| AT-14 | Paritas server | `php -l` bersih, swa-uji 54 cek lulus | `php server/checkin.php` |

Definisi selesai: `flutter analyze` → "No issues found!", `flutter test` hijau, `php -l server/checkin.php` bersih.

## 9. Di luar cakupan paket

Penyimpanan state & ledger, suara, getar, ledakan kelopak, lembar hasil, hero Bipy, bottom sheet "Cara kerja", dan kartu Beranda/Hadiah adalah tanggung jawab host `kelopak_hub`.

## 10. Riwayat

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0 | 24 Nov 2026 | Aturan +1 harian, +3 hari ke-7, produk hari ke-30; record `CheckInAward`, `wibDay`, `DailyCheckInView`. |
| 2.0 | 24 Nov 2026 | Kontrak API v2 (SPEC-CONTRACT §2): `wibDayOf`/`wibWeekdayOf`/`wibDateOf`, kelas `CheckInAward` (`dailyKelopak`, `bonusKelopak`, `productEntitled`, `totalKelopak`), `liveStreak`, `isClaimedOn`, `filledInWeek`, `dayInMonthCycle`, parameter `lastClaimDay`. `DailyCheckInView` diganti tiga widget bertema Kebun Bipy (`CheckInWeekTrack`, `CheckInMonthProgress`, `CheckInClaimButton`) yang hanya memakai tema host. Server `CheckInEngine` + swa-uji. Test unit & widget lengkap (termasuk teks 200%). |
