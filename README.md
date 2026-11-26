# daily_checkin · Check-in Harian v3 (Bpedia Demo)

Halaman game Check-in Harian siap pakai beserta aturan murninya. +1 Kelopak per tanggal WIB, bonus +3 tiap hari ke-7 beruntun, 1 produk gratis tiap hari ke-30. Bipy bergerak, koin terbang ke saldo, konfeti, kisi 30 hari di lipatan pertama, dan lembar hasil berpodium yang menyebut saldo baru beserta nilai rupiahnya. Hanya bergantung pada Flutter SDK.

| Siap klaim | Gelap | Hasil bonus | Hari ke-30 |
|---|---|---|---|
| ![](docs/shots/halaman_siap_terang.jpg) | ![](docs/shots/halaman_siap_gelap.jpg) | ![](docs/shots/klaim_bonus_hasil.jpg) | ![](docs/shots/klaim_hari30_hasil.jpg) |

Lembar animasi klaim (12 bingkai, 130 ms): `docs/shots/klaim_biasa_strip.jpg`. Hasil klaim biasa dengan ajakan Roda Sabtu: `klaim_biasa_hasil.jpg`. Halaman penuh: `halaman_siap_panjang_terang.jpg`, `halaman_sudah_panjang_terang.jpg`, `halaman_hari30_panjang_gelap.jpg`. Tamu: `halaman_tamu_terang.jpg`. Teks 200% di lebar 360: `halaman_teks200.jpg`. Panel uji contoh: `contoh_panel_uji.jpg`. Semua JPG (kualitas 80-85), tiap berkas < 500 KB; sumber PNG dibuat ulang oleh tes tangkap layar ke `build/shots/`.

## Pasang

Selama pengembangan lima repo Bpedia Demo v3 berdampingan di satu folder:

```yaml
dependencies:
  daily_checkin:
    path: ../bpedia-daily-checkin
```

Dependensi git ber-tag (`git: url/ref`) menyusul setelah repo dan tag rilis dibuat pemilik.

Aset (`assets/bipy/`, `assets/art/`, `assets/fx/`) ikut paket dan dirujuk dengan `package: daily_checkin`. Font mengikuti tema host (Bpedia memakai Poppins).

## Pakai

Pola: aturan murni → `CheckInViewState` tak-berubah → `CheckInController` abstrak → `CheckInPage`. Host mengisi satu pengendali; halaman tidak tahu data datang dari mana.

```dart
class HubCheckInController extends CheckInController {
  @override
  CheckInViewState get state => CheckInViewState.fromProgress(
        today: wibDayOf(clock.now()),
        lastClaimDay: store.lastClaimDay,
        storedStreak: store.streak,
        balance: wallet.balance,
        signedIn: auth.isLoggedIn,
        nextResetAt: nextWibMidnight(),
        rewardProduct: const CheckInRewardProduct(
          code: 'P39A06S01000089',
          name: 'Animate Whitening Day Cream 10 g',
          image: AssetImage('assets/catalog/img/P39A06S01000089-1.webp'),
          price: 19900,
        ),
        soundOn: settings.soundOn,
      );

  @override
  Future<CheckInClaimResult?> claim() async { /* kirim, simpan, notifyListeners() */ }
  @override
  bool get wheelReady => wheel.isSaturday && !wheel.spunToday;

  @override
  void openWheel() => router.push('/hadiah/roda');
  // refresh, openLogin, openShop, openCart, openProduct, openTerms, playCue, setSoundOn
}

Navigator.push(context, MaterialPageRoute<void>(
  builder: (_) => CheckInPage(controller: controller),
));
```

Untuk contoh dan tes: `LocalCheckInController(clock: ..., streak: 3, balance: 24, rewardProduct: ...)`.

## API

| Simbol | Ringkas |
|---|---|
| `CheckInPage({required CheckInController controller, VoidCallback? onBack, bool showResultSheet = true})` | Halaman lengkap. `CheckInPage.primaryButtonKey` = kunci tombol utama. |
| `abstract class CheckInController extends ChangeNotifier` | `CheckInViewState get state`, `DateTime now()`, `Future<void> refresh()`, `Future<CheckInClaimResult?> claim()` (null bila sudah klaim atau tamu; lempar bila gagal), `openLogin()`, `openShop()`, `openCart()`, `openProduct(String code)`, `openTerms()`, `playCue(GameCue cue)`, `setSoundOn(bool value)`, `bool get wheelReady` (bawaan `false`) dan `openWheel()` untuk ajakan "Lanjut putar Roda Sabtu" di lembar hasil. |
| `CheckInViewState({required signedIn, required balance, required streak, required claimedToday, nextResetAt, rewardProduct, soundOn, busy = false})` | Juga `.guest({rewardProduct, soundOn})` dan `.fromProgress({required today, required lastClaimDay, required storedStreak, required balance, ...})`. Turunan: `weekFilled`, `monthDay`, `monthCycleStart`, `todayStreakDay`, `todayKelopak`, `todayIsBonus`, `todayGrantsProduct`, `daysToBonus`, `daysToProduct`, `copyWith`. |
| `CheckInRewardProduct({required code, required name, required image, required price, strikePrice})` | Data tampilan produk hari ke-30. |
| `CheckInClaimResult({required award, required balance, product})` | Hasil klaim: `CheckInAward` dari aturan murni, saldo baru, produk bila menang. |
| `LocalCheckInController` | Memori: `advanceDays`, `seed`, `reset`, `signedIn`, `rewardProduct`, `latency`, `failNextClaim`, `wheelReady`, `actions`, `productsWon`. |
| `GameCue` | Isyarat suara: `tap`, `claim`, `bonus`, `winProduct`, `softError` (dipakai halaman ini). |
| Widget di halaman | `CheckInHowTo` (kartu 3 aturan), `CheckInCycleHeader` ("Hari ke-N dari 30" + hadiah), `CheckInMonthGrid` (kisi 30 hari, `todayAnchorKey`, `rewardImage`), `CheckInTerms` (Ketentuan), `showCheckInRulesSheet`, `LivelyPose`. |
| Widget lepas untuk host | `CheckInWeekStrip`, `CheckInMonthProgress`, `TulipPot`, `CheckInRewardCard` (tidak dipakai `CheckInPage`). |
| Aset | `CheckInArt` (koin, kado, kalender, tulip 1–5, pose Bipy, stiker), `CheckInSprites.idle` / `.jump`. |
| Format | `formatRupiah`, `countdownClock`, `countdownSpoken`, `streakMessage`, `weekTileSemantics`, `balanceSentence`, `nextBonusNote`. |
| Aturan murni (tetap dari v2) | `CheckInRules`, `evaluateCheckIn`, `CheckInAward`, `liveStreak`, `isClaimedOn`, `filledInWeek`, `dayInMonthCycle`, `wibDayOf`, `wibWeekdayOf`, `wibDateOf`. |

## Perilaku

- Tamu melihat halaman utuh; tombol utama "Masuk untuk check-in" dan chip saldo memanggil `openLogin`.
- Sudah klaim: tombol "Kembali besok" nonaktif dengan hitung mundur ke 00.00 WIB; saat lewat tengah malam halaman memanggil `refresh()`.
- Kurangi gerak (`MediaQuery.disableAnimations`) mematikan denyut, stempel, koin terbang, gerak Bipy, dan gulir animasi.
- Bonus +3 dihitung per hari streak (kelipatan 7), sama dengan server. Siklus 30 hari kedua menggeser sel bonus mengikuti streak sebenarnya (streak 31-60: posisi 5/12/19/26).
- Teks tahan skala 200% di lebar 360 (diuji terang dan gelap); kisi berganti 5 kolom pada huruf besar.

## Contoh

`example/` membawa runner Android, iOS, dan web (dibuat dengan `flutter create --platforms=android,ios,web --org id.bpedia`), jadi klon bersih bisa langsung jalan:

```bash
cd example
flutter pub get
flutter run -d chrome        # atau perangkat Android/iOS
```

Bila folder platform terhapus, pulihkan tanpa menimpa `lib/` contoh: `flutter create --platforms=android,ios,web --org id.bpedia --project-name daily_checkin_example .` lalu hapus `test/widget_test.dart` bawaan.

Tombol kembali di contoh membuka **Panel uji**: besok / lompat 2 hari, susun streak (0, 3, 6, 13, 20, 29, 34), masuk/tamu, produk host, jaringan lambat, gagalkan klaim, Roda Sabtu siap, tema gelap, kurangi gerak, catatan aksi, atur ulang.

## Server

`server/checkin.php` mencerminkan aturan yang sama dan menyediakan `claimDay(array &$state, int $today): string`.

## Perintah

```bash
flutter analyze
flutter test --concurrency=3            # semua tes
flutter test --concurrency=3 test/shots # tangkapan layar ke build/shots/
php server/checkin.php                  # swa-uji aturan server
```

Dokumen: `PRD.md` (produk v3), `CHANGELOG.md`, `PROGRESS-M1.md` (catatan pembangunan), `PROGRESS-FIX-M1.md` (putaran perbaikan).

## Lisensi

Lisensi belum ditetapkan pemilik.
