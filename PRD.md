# PRD 01 · Check-in Harian v3 (Bpedia Demo)

Paket `daily_checkin` 3.0.0. Pemilik: Muhammad Yusuf. Disusun 26 Nov 2026.
Acuan desain: `SPEC-V3.md` §6.1 dan rancangan "Daily Sign In" desainer owner (kisi 30 hari, 7 kolom, spanduk hadiah, tombol Check-in besar).

## 1. Tujuan

1. Alasan membuka Bpedia setiap hari dengan **satu ketukan**: tombol permen "Check-in sekarang" yang selalu terlihat di bawah layar.
2. Terasa seperti game meriah, bukan formulir: Bipy bergerak dan bereaksi, koin terbang ke saldo, konfeti, tulip yang tumbuh, lembar hasil berpodium.
3. Pengguna selalu tahu: hari ke berapa, apa yang didapat hari ini, kapan bonus +3 dan produk gratis, dan kapan bisa kembali.
4. Halaman tidak tahu sumber data: host (Kelopak Hub) mengisi satu `CheckInController`.

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

### 4.1 Susunan halaman (`CheckInPage`)

| Bagian | Isi |
|---|---|
| Hero pesta | Judul "Klaim Kelopak", ringkas aturan, chip saldo Kelopak (tujuan koin terbang), chip streak, Bipy sprite diam (ketuk = lompat), koin dan stiker melayang dengan paralaks. App bar: kembali, suara (bila host memberi status), "Aturan". |
| Minggu ini | Strip 7 ubin (+1 ×6, hari ke-7 +4 berpita "Bonus"), ubin hari ini berpita "Hari ini" dan berdenyut, stempel saat klaim, kalimat streak. |
| Menuju produk gratis | Tulip tumbuh 5 tahap (tonggak 7/14/21/30), bar progres bertonggak, kisi 30 hari 7 kolom (sel bonus emas +3 mengikuti hari streak sebenarnya, hari ke-30 berkado), spanduk "30 hari = 1 produk gratis", legenda, kartu produk hadiah dari host. |
| Cara main | Tiga langkah bergambar, "1 Kelopak = Rp100", tautan syarat. |
| Bar bawah | Satu tombol permen: siap = "Check-in sekarang" + hadiah hari ini; sudah = "Kembali besok" + hitung mundur ke 00.00 WIB; tamu = "Masuk untuk check-in". |

### 4.2 Urutan klaim

Ketuk tombol → gulir ke atas bila perlu → `controller.claim()` → ubin hari ini membal dan distempel → Bipy lompat, konfeti, koin terbang dari ubin ke chip saldo (saldo ditahan sampai koin pertama tiba lalu hitung naik) → hari bonus: meriam konfeti → lembar hasil:

| Klaim | Lembar hasil |
|---|---|
| Biasa | "Berhasil!", koin di podium, +1 Kelopak, sisa hari ke bonus, Bipy pose bintang. |
| Hari ke-7/14/21/28/… | "Bonus!", kado terbuka, +4 Kelopak, Bipy pose mawar. |
| Hari ke-30/60/… | "Selamat!", foto produk di podium, nama produk, "Lihat keranjang" (`openCart`), Bipy pose lompat bintang. |

Gagal kirim → snackbar "Check-in belum berhasil. Periksa koneksimu, lalu coba lagi." dan tombol tetap siap. Ketukan ganda diabaikan.

### 4.3 Suara

Halaman memanggil `controller.playCue(GameCue)`: `tap`, `claim` (koin pertama tiba), `bonus`, `winProduct`, `softError`. Host memetakan ke berkas audio.

### 4.4 Aksesibilitas

- Target sentuh ≥ 48 dp; tombol, ubin, kisi, progres, tulip, dan kartu hadiah punya label Semantics (mis. "Hari 4, hari ini, belum check-in").
- Teks ikut skala 200% di lebar 360 tanpa luapan (diuji di kedua tema); strip 7 hari turun baris bila sempit, pita ubin ikut membesar. Judul pajangan hero dibatasi 1,6x.
- `MediaQuery.disableAnimations`: tanpa denyut, stempel, gulir animasi, koin terbang, maupun gerak Bipy; hasil tetap tampil.

## 5. API publik (`package:daily_checkin/daily_checkin.dart`)

| Simbol | Peran |
|---|---|
| `CheckInViewState` | Keadaan tak-berubah: `signedIn`, `balance`, `streak`, `claimedToday`, `nextResetAt`, `rewardProduct`, `soundOn`, `busy`; turunan `weekFilled`, `monthDay`, `monthCycleStart`, `todayKelopak`, `todayIsBonus`, `todayGrantsProduct`, `daysToBonus`, `daysToProduct`. `CheckInViewState.fromProgress(...)`, `.guest(...)`. |
| `CheckInRewardProduct` | Data tampilan produk hari ke-30: `code`, `name`, `image`, `price`, `strikePrice`. |
| `CheckInController` | `abstract class ... extends ChangeNotifier`: `state`, `now()`, `refresh()`, `claim()` → `CheckInClaimResult?`, `openLogin`, `openShop`, `openCart`, `openProduct(code)`, `openTerms`, `playCue(GameCue)`, `setSoundOn(bool)`. |
| `LocalCheckInController` | Pengendali memori untuk contoh dan tes (geser hari, susun streak, jeda, gagal sekali, catatan aksi). |
| `CheckInPage` | `CheckInPage({required controller, onBack, showResultSheet = true})`. |
| Widget | `CheckInWeekStrip`, `CheckInMonthGrid`, `CheckInMonthProgress`, `TulipPot`, `CheckInRewardCard`, `CheckInHowTo`, `showCheckInRulesSheet`, `LivelyPose`. |
| Aturan murni | `CheckInRules`, `evaluateCheckIn`, `liveStreak`, `isClaimedOn`, `filledInWeek`, `dayInMonthCycle`, `wibDayOf` dkk. (tidak berubah dari v2). |

## 6. Server (`server/checkin.php`, tidak berubah)

- `CheckInEngine::wibDayOf`, `wibWeekdayOf`, `wibDateOf`, `evaluate`, `liveStreak`, `isClaimedOn`, `filledInWeek`, `dayInMonthCycle` (cermin fungsi Dart).
- `claimDay(array &$state, int $today): string` · kompatibel dengan router demo hub (`server/index.php`): memperbarui `streak`, `lastDay`, `balance`, `products`; mengembalikan label riwayat ("+1 Kelopak + bonus 3 Kelopak · Hari ke-7"); melempar `DomainException` ("Kamu sudah check-in hari ini. Kembali besok mulai 00.00 WIB.") untuk klaim ganda.
- `php server/checkin.php` menjalankan swa-uji tabel yang sama dengan test Dart (54 cek). Di SAPI web tidak ada keluaran.


## 7. Uji penerimaan

- Tes aturan v2 (`check_in_engine_test.dart`, `wib_calendar_test.dart`) tidak disentuh dan lolos.
- Tes unit ViewState, pengendali lokal, format; tes widget (kasus v2 dibawa ke strip/kisi/progres baru); tes halaman (tamu, klaim biasa/bonus/produk, gagal, ketukan ganda, pergantian hari WIB, suara, aturan, kartu hadiah, skala teks 200% kedua tema).
- `flutter analyze` 0 isu. Tangkapan layar terang + gelap dan lembar animasi di `docs/shots/`.

## 8. Di luar cakupan paket

Penyimpanan, ledger, hadiah menunggu di keranjang, dan pengiriman produk ada di `kelopak_hub`. Paket ini tidak memakai plugin.
