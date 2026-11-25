# PROGRESS-M1 · Check-in Harian v3

Agen: M1. Repo: `bpedia-daily-checkin` (paket `daily_checkin`). Mulai 25 Nov 2026.

## Tonggak

- [x] T0 Baca RENCANA, BRIEF, SPEC §2.4 §6.1 §7 §8 §10 §11, ARSITEKTUR §0 §1.1 §1.5, KEPUTUSAN, README kit, rujukan owner (Figma, REF-ECOM-A/B, 3 gambar rujukan)
- [x] T1 Dasar: `pubspec.yaml` (aset), `analysis_options.yaml`, `check_in_view.dart` (ViewState, Controller), `local_check_in_controller.dart`, `check_in_assets.dart`, `check_in_format.dart` + tes unit
- [x] T2 Widget (kode; tes widget di T3): strip 7 ubin, kisi 30 hari, bar tonggak + tulip, kartu produk hadiah, cara main, pose hidup + tes widget
- [x] T3 Halaman (tes: 51 unit, 34 widget, 32 halaman lolos 26 Nov) `CheckInPage` (hero, urutan klaim, lembar hasil, tamu, kurangi gerak) + tes alur
- [x] T4 Tangkap layar terang + gelap, strip animasi, putaran lihat-perbaiki 1 (26 Nov: hiasan hero digeser dari teks, judul hero 'Klaim Kelopak' dibatasi 1,6x, pita ubin turun ikut skala teks, lembar hasil produk tak lagi crash AspectRatio)
- [x] T5 Putaran lihat-perbaiki 2 (judul hero dibatasi, judul progres '3 dari 30 hari', dibandingkan dengan Figma owner), 13 PNG di `docs/shots/`
- [x] T6 `example/` (app + panel uji; tombol kembali membuka panel; 2 tes di `example/test`)
- [x] T7 Dokumen: README, PRD v3, CHANGELOG 3.0.0
- [x] T8 `flutter analyze` 0 isu, `flutter test --concurrency=3` 198 lolos (+2 di `example/`), commit lokal (26 Nov)

## Keputusan

- Kit (`lib/src/kit/`) tidak diubah. Aturan lint repo ini (`public_member_api_docs`, `avoid_redundant_argument_values`) menghasilkan 214 info di berkas kit, jadi `lib/src/kit/**` dikecualikan dari analyzer di `analysis_options.yaml`; kit dianalisis di stagingnya (`v3/kit_src`). Kode modul tetap memakai semua aturan lama.
- Satu aksi utama: tombol permen menempel di bar bawah `GameScaffold` (selalu terlihat saat strip 7 hari maupun kisi 30 hari digulir). Saat ditekan dari posisi tergulir, halaman naik dulu ke atas supaya perayaan terlihat.
- Bonus di kisi 30 hari dihitung dari hari streak sebenarnya (`hariStreak % 7 == 0`), jadi di siklus pertama jatuh di hari 7/14/21/28 dan tetap jujur di siklus berikutnya.
- Tiap klaim ditutup `ResultSheet` (pola pop-up hasil check-in rujukan owner): biasa = +1 Kelopak, hari ke-7 = +4 dengan kado terbuka, hari ke-30 = produk gratis.
- `GameCue` diekspor dari barrel karena dipakai di `CheckInController.playCue`.

## Berkas tes

- `test/support/check_in_harness.dart`: jam tetap 26 Nov 2026 10.00 WIB, `localController(...)`, `checkInPageApp(...)`, produk demo dari `example/assets/products/`.
- `test/shots/check_in_page_shot_test.dart`, `test/shots/check_in_claim_shot_test.dart`.

## Cara melanjutkan

1. `git log --oneline` dan daftar tonggak di atas.
2. Iterasi: `flutter test --concurrency=3 test/<berkas>`; tangkap layar: `flutter test --concurrency=3 test/shots`; lihat PNG di `build/shots/`.
3. Tes penuh hanya di tonggak: `flutter analyze` lalu `flutter test --concurrency=3`.

## Catatan untuk kit (tidak diubah, dicatat untuk orkestrator)

- `ResultSheet` membungkus slot `art` dengan `FittedBox`, jadi isi tanpa ukuran tetap (mis. `AspectRatio`) gagal tata letak. Modul ini memberi `SizedBox.square(160)`; dokumentasi kit sebaiknya menyebut slot butuh ukuran tetap.
- Judul app bar `GameScaffold` terpotong ("Check...") pada teks 200% di lebar 360 karena aksi "Aturan" dan suara; masih terbaca lewat Semantics.
