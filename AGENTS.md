# AGENTS.md · bpedia-daily-checkin

Berlaku untuk Codex, Antigravity, Claude, dan agen lain. Bahasa kerja: Indonesia.

1. Baca PRD pusat dulu: `../bpedia-kelopak-hub/PRD.md`
   (online: https://github.com/yusufmuh/bpedia-kelopak-hub/blob/main/PRD.md)
2. Kontrak v2 di hub: `../bpedia-kelopak-hub/docs/SPEC-CONTRACT.md` (aturan bisnis §1, API publik §2) dan `../bpedia-kelopak-hub/docs/SPEC-UIUX.md` (layar 3.6 Check-in Harian).
3. Lalu `PRD.md` di repo ini untuk detail fitur, dan `README.md` untuk cara pakai.
4. Aturan kerja, kualitas, dan larangan mengikuti `../bpedia-kelopak-hub/AGENTS.md`.

Repo ini berisi paket Flutter (`lib/`, ekspor tunggal `lib/daily_checkin.dart`, implementasi di `lib/src/`) dan cermin aturan server (`server/checkin.php`).

- Aturan ekonomi dan nama/signature API publik tidak diubah di sini; ubah dulu di SPEC-CONTRACT hub dengan persetujuan owner.
- Perubahan aturan wajib sama di Dart dan PHP, lalu tabel uji di kedua sisi diperbarui.
- Widget hanya memakai `Theme.of(context)`; teks UI tanpa glyph `≥ → ✓`.
- Sebelum selesai: `flutter analyze` → "No issues found!", `flutter test` hijau, `php -l server/checkin.php` dan `php server/checkin.php` lulus. Perbarui bagian Riwayat di `PRD.md`.
