# Changelog

## 3.0.0 · 26 Nov 2026

Rombakan tampilan untuk Bpedia Demo v3. Aturan murni tidak berubah.

### Baru

- `CheckInPage`: halaman game lengkap (hero pesta dengan Bipy bergerak, strip "Minggu ini", kisi 30 hari "Menuju produk gratis", cara main, tombol permen menempel di bawah).
- Pola D2: `CheckInViewState` tak-berubah, `CheckInController` abstrak, `LocalCheckInController` untuk contoh dan tes, `CheckInRewardProduct` sebagai data tampilan produk hari ke-30, `CheckInClaimResult`.
- Urutan klaim: stempel ubin, Bipy lompat, konfeti, koin terbang ke chip saldo dengan hitung naik, meriam konfeti di hari bonus, lembar hasil (biasa, bonus, produk gratis) dengan pose Bipy berbeda.
- Widget: `CheckInWeekStrip`, `CheckInMonthGrid` (bonus mengikuti hari streak sebenarnya di tiap siklus), `CheckInMonthProgress` + `TulipPot` (5 tahap), `CheckInRewardCard`, `CheckInHowTo`, `showCheckInRulesSheet`, `LivelyPose`.
- Aset paket: sprite Bipy diam/lompat, seni 3D (koin, kado, kalender, tulip 1–5), pose Bipy, stiker hias. `CheckInArt`, `CheckInSprites`.
- Kit pesta di `lib/src/kit/` (salinan identik dari `bpedia_kit`); `GameCue` diekspor.
- Format: `formatRupiah`, `countdownClock`, `countdownSpoken`, `streakMessage`, `weekTileSemantics`.
- `example/`: aplikasi contoh dengan panel uji.
- Tes unit, widget, halaman, dan tangkapan layar terang + gelap.

### Dihapus

- Widget v2 `CheckInWeekTrack`, `CheckInMonthProgress` (v2), `CheckInClaimButton`, `TulipPainter` dan berkas tesnya; kasus tesnya dibawa ke widget v3.

## 2.0.0

Aturan murni hari WIB, widget bertema, PRD v2.
