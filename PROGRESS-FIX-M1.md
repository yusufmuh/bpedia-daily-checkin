# PROGRESS-FIX-M1 · Check-in Harian (putaran perbaikan)

Agen: M1. Repo: `bpedia-daily-checkin`. Mulai 26 Nov 2026. Lingkup: seluruh repo kecuali `lib/src/kit/` dan `test/support/shot.dart`.

## Temuan

- [x] P3-01 Komposisi halaman mengikuti Figma/desainer: hero "Check-in Harian", kartu 3 aturan, kisi 30 hari di lipatan pertama, ketentuan di bawah kisi
- [x] P3-15 Lembar hasil: saldo baru + nilai rupiah, pil streak, catatan bonus, ajakan lanjutan dari host
- [x] P3-16 Bonus setelah siklus 30 hari konsisten dengan kisi (keputusan: opsi b, lihat bawah)
- [ ] R1-04 Runner `example/` (android, ios, web) + README langkah jalan
- [ ] R1-13 docs/shots JPG < 500 KB per berkas, README (lisensi dan git ber-tag = urusan rilis orkestrator)

## Keputusan

- P3-16: aturan bonus tetap per streak (hari streak kelipatan 7) sesuai KEPUTUSAN/SPEC dan server `checkin.php` di hub. Kontradiksi hilang karena strip "Minggu ini" dan bar tonggak 7/14/21/30 dihapus; kisi menandai sel bonus dari hari streak sebenarnya. Mengganti ke opsi (a) butuh konfirmasi owner dan perubahan server hub (di luar lingkup).

## Cara melanjutkan

1. `git log --oneline | head` dan centang di atas.
2. Iterasi: `flutter test --concurrency=3 test/<berkas>`; tangkap layar `flutter test --concurrency=3 test/shots` lalu `build/shots/`.
