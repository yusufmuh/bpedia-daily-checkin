# PRD 01 · Check-in Harian (Bpedia Kelopak)

**Versi 1.0 (Final & Resmi) · 24 November 2026 · Owner: Muhammad Yusuf (Bpedia)**  
Dokumen spesifikasi teknis dan aturan bisnis modul Check-in Harian Bpedia Kelopak.  
Induk acuan: `bpedia-kelopak-hub/PRD.md`.

---

## 1. Tujuan & Nilai bagi Pengguna
Memberikan pembeli alasan untuk membuka aplikasi Bpedia setiap hari. Setiap hari pembeli dapat mengklaim **1 Kelopak** (= Rp100). Pengguna melihat riwayat jejak 7 hari, status hari ini, serta jarak kemajuan menuju hak produk gratis (30 hari).

---

## 2. Aturan Ekonomi & Kalender

| Peristiwa | Perubahan Saldo | Nilai Rupiah | Keterangan |
|---|---|---|---|
| **Hari ke-1 s/d ke-6** | +1 Kelopak per hari | Rp100 per hari | Klaim harian normal |
| **Hari ke-7 (Strike 1 Minggu)** | +1 harian & **+3 bonus** | +Rp400 hari ke-7 | **Total akumulasi 7 hari = 10 Kelopak = Rp1.000** |
| **Hari ke-8 s/d ke-13** | +1 Kelopak per hari | Rp100 per hari | Melanjutkan siklus minggu kedua |
| **Hari ke-14 (Strike 2 Minggu)**| +1 harian & **+3 bonus** | +Rp400 hari ke-14 | Bonus mingguan kedua |
| **Hari ke-30 (Strike 1 Bulan)** | +1 harian & **1 Hak Produk Gratis** | +Rp100 & Produk | Hak klaim produk gratis diterbitkan ke akun |
| **Terlewat 1 Hari (Bolong)** | Streak kembali ke Hari 1 | - | Saldo Kelopak dan hak produk terdahulu **tetap aman** |

### Ketentuan Waktu Server:
- Kalender pergantian hari dihitung berdasarkan zona waktu **Asia/Jakarta (WIB, UTC+07:00)** pukul **00.00 WIB**.
- Jam pada perangkat klien tidak mempengaruhi validasi server.
- Satu akun hanya berhak melakukan satu kali klaim per tanggal kalender WIB.

---

## 3. Komponen Antarmuka & Aksesibilitas
1. **Jejak 7 Hari**: Baris 7 kartu penanda hari dengan ikon dan teks status yang jelas:
   - Hari tercapai: Latar Blush Soft `#F6CFDA`, ikon centang `check_circle`.
   - Hari ke-7: Ikon hadiah spesial `card_giftcard`.
   - Hari belum tercapai: Latar Blush `#F9F0EF`, ikon bunga `spa_outlined`.
2. **Tombol Klaim**:
   - Belum klaim: Teks *"Ambil 1 Kelopak"*, tombol aktif (Berry `#982149`).
   - Sudah klaim: Teks *"Sudah check-in hari ini"*, tombol nonaktif (`disabled`).
3. **Progres Produk Bulanan**:
   - `LinearProgressIndicator` persentase hari menuju target 30 hari.
   - Keterangan teks: `X dari 30 hari berturut-turut · Y hak produk`.
4. **Aksesibilitas**: Dibungkus `Semantics` lengkap untuk pembaca layar (TalkBack & VoiceOver).

---

## 4. Spesifikasi Kontrak Backend
- Endpoint: `POST /v1/checkin/claim`
- Header: `Authorization: Bearer <token>`, `Idempotency-Key: <uuid>`
- Respons Sukses (200 OK):
  ```json
  {
    "receiptId": "chk-12345",
    "awarded": 1,
    "bonus": 0,
    "streak": 5,
    "newBalance": 5,
    "productEntitled": false
  }
  ```
- Respons Duplikasi / Sudah Klaim (409 Conflict):
  ```json
  {
    "error": "already_claimed",
    "message": "Check-in hari ini sudah tercatat."
  }
  ```

---

## 5. Pengujian Mutu (Test Scenarios)
1. Klaim pertama menghasilkan streak 1 dan saldo +1.
2. Klaim pada hari ke-7 berturut-turut menghasilkan total +4 (1 harian + 3 bonus), saldo total 10.
3. Klaim pada hari ke-30 berturut-turut menghasilkan hak produk gratis.
4. Klaim yang terlewat 1 hari mereset streak menjadi 1 tanpa mengurangi saldo lama.
5. Permintaan klaim ganda dengan idempotency key yang sama tidak menambah saldo dua kali.
