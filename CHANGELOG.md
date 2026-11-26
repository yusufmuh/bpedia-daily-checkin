# Changelog

## 3.0.0 · 26 Nov 2026

Rombakan tampilan untuk Bpedia Demo v3. Aturan murni tidak berubah.

### Baru

- `CheckInPage`: halaman game lengkap mengikuti rancangan desainer owner: hero "Check-in Harian" dengan Bipy bergerak dan kalimat streak, kartu 3 aturan, baris "Hari ke-N dari 30" + hadiah, kisi 30 hari berlabel "Hari N" di lipatan pertama, Ketentuan, tombol permen menempel di bawah.
- Lembar hasil menyebut saldo baru dan nilai rupiahnya, pil streak, sisa hari menuju bonus, dan mengajak "Lanjut putar Roda Sabtu" bila host siap (`CheckInController.wheelReady` / `openWheel`).
- Pola D2: `CheckInViewState` tak-berubah, `CheckInController` abstrak, `LocalCheckInController` untuk contoh dan tes, `CheckInRewardProduct` sebagai data tampilan produk hari ke-30, `CheckInClaimResult`.
- Urutan klaim: stempel ubin, Bipy lompat, konfeti, koin terbang ke chip saldo dengan hitung naik, meriam konfeti di hari bonus, lembar hasil (biasa, bonus, produk gratis) dengan pose Bipy berbeda.
- Widget: `CheckInMonthGrid` (sel bonus berkepala pink mengikuti hari streak sebenarnya di tiap siklus, 5 kolom pada huruf besar), `CheckInCycleHeader`, `CheckInHowTo` (kartu 3 aturan), `CheckInTerms`, `showCheckInRulesSheet`, `LivelyPose`. Widget lepas untuk host: `CheckInWeekStrip`, `CheckInMonthProgress` + `TulipPot` (5 tahap), `CheckInRewardCard`.
- Aset paket: sprite Bipy diam/lompat, seni 3D (koin, kado, kalender, tulip 1–5), pose Bipy, stiker hias. `CheckInArt`, `CheckInSprites`.
- Kit pesta di `lib/src/kit/` (salinan identik dari `bpedia_kit`); `GameCue` diekspor.
- Format: `formatRupiah`, `countdownClock`, `countdownSpoken`, `streakMessage`, `weekTileSemantics`, `balanceSentence`, `nextBonusNote`.
- `example/`: aplikasi contoh dengan panel uji dan runner Android, iOS, web.
- Tes unit, widget, halaman, dan tangkapan layar terang + gelap (`docs/shots/`, JPG).

### Dihapus

- Widget v2 `CheckInWeekTrack`, `CheckInMonthProgress` (v2), `CheckInClaimButton`, `TulipPainter` dan berkas tesnya; kasus tesnya dibawa ke widget v3.

## 2.0.0

Aturan murni hari WIB, widget bertema, PRD v2.
