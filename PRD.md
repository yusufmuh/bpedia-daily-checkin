# PRD 01 · Check-in Harian

**Versi 0.1 · 24 November 2026 · Pemilik keputusan bisnis: tim produk Bpedia**

## Tujuan dan perjalanan pengguna
Pembeli yang membuka Bpedia dapat mengambil 1 Kelopak setiap hari. Ia melihat manfaat hari ini, kemajuan minggu berjalan, dan jarak menuju produk gratis sebelum menyentuh tombol. Setelah klaim berhasil, tampilkan tanggal WIB, rincian tambahan harian dan bonus, serta saldo hasil transaksi. Pengunjung yang belum masuk kembali ke layar yang sama sesudah login.

## Ekonomi dan kalender
| Peristiwa | Perubahan | Contoh tanpa transaksi lain |
|---|---|---|
| Hari pertama | +1 Kelopak | Saldo 1, setara Rp100 |
| Hari ketujuh berturut-turut | +1 harian dan +3 bonus | Saldo 10, setara Rp1.000 |
| Hari ke-10 | +1 harian | Saldo 13 |
| Hari ke-14 | +1 harian dan +3 bonus | Saldo 20 |
| Hari ke-30 | +1 harian dan satu hak produk gratis | Saldo 42 dan satu hak produk |
| Ada satu tanggal terlewat | Mulai rentetan baru pada klaim berikutnya | Saldo dan hak terdahulu tetap ada |

Kalender server Asia/Jakarta berganti pukul 00.00 WIB. Satu akun hanya bisa mengklaim satu kali per tanggal. Bulan ditafsirkan **30 tanggal berurutan** dan hadiah berulang saat kelipatan 30 sebagai asumsi desain. Contoh 30 hari mengandung empat bonus mingguan. Anggaran per rentetan 30 hari ialah Rp4.200 ekuivalen Kelopak ditambah biaya produk, penanganan, dan kemungkinan subsidi kirim. Operasional menetapkan SKU, ongkir, wilayah, kuota jaminan, dan jangka klaim sebelum promo dibuka.

## Tampilan dan pemulihan
Tujuh penanda hari memiliki nomor dan status teks. Tampilkan tombol “Ambil 1 Kelopak” atau “Sudah check-in hari ini”. Layar dapat digulir saat teks diperbesar. Jika pengiriman klaim terputus, muat ulang bukti dari server sebelum mengizinkan percobaan berikutnya. Jika produk kosong setelah milestone tercapai, simpan hak sebagai menunggu pemenuhan dan beri kanal bantuan; operator harus bisa menelusuri ID hak. Hari yang telah diklaim dari iPhone juga harus terlihat di Android dan web.

## Kontrak transaksi produksi
Server mengambil identitas dari sesi, menghitung tanggal dan mengunci baris akun. Satu transaksi menulis klaim unik (akun, tanggal WIB), entri ledger harian, entri bonus unik (akun, awal rentetan, milestone) dan hak produk bila memenuhi syarat. Kirim peristiwa pemenuhan memakai outbox setelah commit. Respons mengembalikan receipt, saldo integer, streak, tanggal terakhir, waktu klaim berikutnya, serta status produk. Idempotency key yang sama menghasilkan receipt yang sama. Konflik permintaan dengan key berbeda di hari yang sama mengembalikan status klaim yang tercatat.

## Uji penerimaan
1. Pada tengah malam WIB dua klaim yang mengapit pergantian tanggal bisa sah; perbedaan jam/zonasi perangkat tidak mengubah keputusan server.
2. Hari ke-7 memberi empat Kelopak pada transaksi hari itu; total tujuh hari sepuluh. Hari ke-10 memberi satu. Hari ke-14 mendapat bonus lagi.
3. Dua perangkat yang mengirim bersamaan menghasilkan satu klaim dan satu perubahan saldo. Putus jaringan sesudah commit lalu coba ulang menghasilkan receipt pertama.
4. Klaim setelah satu hari terlewat memulai hari pertama. Hari ke-30 menghasilkan satu hak produk, dan pembukaan ulang layar menampilkan hak yang sama.
5. Pengguna dapat membaca status sudah diklaim, offline, dan stok tertunda dengan pembaca layar.

## Pengukuran dan keputusan
Ukur akun yang mengklaim ÷ akun yang membuka fitur, proporsi yang mencapai hari 7/30 menurut kohor, biaya manfaat per akun, kegagalan tulis, dan selisih ledger. Product menyetujui definisi bulan dan kebijakan stok, operasional memastikan ketersediaan, backend memverifikasi transaksi, QA membuktikan alur lintas perangkat.
