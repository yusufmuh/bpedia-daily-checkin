import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'check_in_engine.dart';
import 'kit/game_cue.dart';

/// Produk hadiah hari ke-30 sebagai data tampilan.
///
/// Modul tidak mengenal katalog: host mengisi nama, gambar, dan harga.
@immutable
final class CheckInRewardProduct {
  /// Membuat data tampilan produk hadiah.
  const CheckInRewardProduct({
    required this.code,
    required this.name,
    required this.image,
    required this.price,
    this.strikePrice,
  });

  /// Kode produk di katalog host.
  final String code;

  /// Nama produk.
  final String name;

  /// Foto produk.
  final ImageProvider image;

  /// Harga jual (rupiah). Di halaman tampil dicoret karena hadiahnya gratis.
  final int price;

  /// Harga sebelum diskon (rupiah), bila ada.
  final int? strikePrice;

  @override
  bool operator ==(Object other) =>
      other is CheckInRewardProduct &&
      other.code == code &&
      other.name == name &&
      other.image == image &&
      other.price == price &&
      other.strikePrice == strikePrice;

  @override
  int get hashCode => Object.hash(code, name, image, price, strikePrice);
}

/// Keadaan halaman Check-in Harian pada satu saat. Tak-berubah.
///
/// Cukup empat fakta: sudah masuk atau belum, saldo, streak yang masih hidup
/// hari ini, dan apakah hari ini sudah diklaim. Posisi di strip 7 hari dan
/// kisi 30 hari diturunkan dengan aturan murni di `check_in_engine.dart`.
@immutable
final class CheckInViewState {
  /// Membuat keadaan dari nilai yang sudah dihitung host.
  const CheckInViewState({
    required this.signedIn,
    required this.balance,
    required this.streak,
    required this.claimedToday,
    this.nextResetAt,
    this.rewardProduct,
    this.soundOn,
    this.busy = false,
  }) : assert(streak >= 0, 'Streak tidak boleh negatif.');

  /// Keadaan tamu: halaman tetap tampil, aksi utama menjadi "Masuk".
  const CheckInViewState.guest({this.rewardProduct, this.soundOn})
    : signedIn = false,
      balance = 0,
      streak = 0,
      claimedToday = false,
      nextResetAt = null,
      busy = false;

  /// Menurunkan keadaan dari data tersimpan memakai aturan murni.
  ///
  /// [today] dan [lastClaimDay] adalah hari WIB (`wibDayOf`), [storedStreak]
  /// streak yang tersimpan bersama klaim terakhir.
  factory CheckInViewState.fromProgress({
    required int today,
    required int? lastClaimDay,
    required int storedStreak,
    required int balance,
    bool signedIn = true,
    DateTime? nextResetAt,
    CheckInRewardProduct? rewardProduct,
    bool? soundOn,
    bool busy = false,
  }) {
    return CheckInViewState(
      signedIn: signedIn,
      balance: balance,
      streak: liveStreak(
        today: today,
        lastClaimDay: lastClaimDay,
        streak: storedStreak,
      ),
      claimedToday: isClaimedOn(today: today, lastClaimDay: lastClaimDay),
      nextResetAt: nextResetAt,
      rewardProduct: rewardProduct,
      soundOn: soundOn,
      busy: busy,
    );
  }

  /// Pengguna sudah masuk. Tamu melihat halaman tanpa bisa klaim.
  final bool signedIn;

  /// Saldo Kelopak.
  final int balance;

  /// Streak yang masih hidup hari ini (0 bila belum ada atau sudah putus).
  final int streak;

  /// Hari WIB ini sudah diklaim.
  final bool claimedToday;

  /// Saat pergantian hari WIB berikutnya (00.00 WIB). `null` = tanpa hitung
  /// mundur.
  final DateTime? nextResetAt;

  /// Produk hadiah hari ke-30. `null` = kartu hadiah umum.
  final CheckInRewardProduct? rewardProduct;

  /// Status suara host. `null` menyembunyikan tombol suara.
  final bool? soundOn;

  /// Sedang memuat atau mengirim klaim: tombol utama menampilkan pemutar.
  final bool busy;

  /// Ubin terisi di strip 7 hari (0..7).
  int get weekFilled =>
      filledInWeek(liveStreak: streak, claimedToday: claimedToday);

  /// Hari terisi di kisi 30 hari (0..30).
  int get monthDay =>
      dayInMonthCycle(liveStreak: streak, claimedToday: claimedToday);

  /// Nomor hari streak untuk hari ini: sudah diklaim = [streak], belum =
  /// [streak] + 1.
  int get todayStreakDay => claimedToday ? streak : streak + 1;

  /// Jumlah hari streak sebelum hari pertama kisi 30 hari yang sedang tampil.
  int get monthCycleStart {
    final int position = claimedToday ? monthDay : monthDay + 1;
    return todayStreakDay - position;
  }

  /// Klaim hari ini (sudah atau belum) jatuh di kelipatan 7.
  bool get todayIsBonus => todayStreakDay % CheckInRules.bonusEvery == 0;

  /// Klaim hari ini (sudah atau belum) memberi produk gratis.
  bool get todayGrantsProduct =>
      todayStreakDay % CheckInRules.productEvery == 0;

  /// Kelopak dari klaim hari ini: 1, atau 4 pada hari bonus.
  int get todayKelopak =>
      CheckInRules.dailyKelopak +
      (todayIsBonus ? CheckInRules.bonusKelopak : 0);

  /// Sisa hari menuju bonus +3 berikutnya, dihitung dari besok. Bernilai 0
  /// bila hari ini hari bonus yang belum diklaim.
  int get daysToBonus {
    final int rest = streak % CheckInRules.bonusEvery;
    if (claimedToday) return CheckInRules.bonusEvery - rest;
    return CheckInRules.bonusEvery - rest - 1;
  }

  /// Sisa klaim menuju produk gratis berikutnya.
  int get daysToProduct => CheckInRules.productEvery - monthDay;

  /// Salinan dengan sebagian nilai diganti.
  CheckInViewState copyWith({
    bool? signedIn,
    int? balance,
    int? streak,
    bool? claimedToday,
    DateTime? nextResetAt,
    CheckInRewardProduct? rewardProduct,
    bool? soundOn,
    bool? busy,
  }) {
    return CheckInViewState(
      signedIn: signedIn ?? this.signedIn,
      balance: balance ?? this.balance,
      streak: streak ?? this.streak,
      claimedToday: claimedToday ?? this.claimedToday,
      nextResetAt: nextResetAt ?? this.nextResetAt,
      rewardProduct: rewardProduct ?? this.rewardProduct,
      soundOn: soundOn ?? this.soundOn,
      busy: busy ?? this.busy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CheckInViewState &&
      other.signedIn == signedIn &&
      other.balance == balance &&
      other.streak == streak &&
      other.claimedToday == claimedToday &&
      other.nextResetAt == nextResetAt &&
      other.rewardProduct == rewardProduct &&
      other.soundOn == soundOn &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(
    signedIn,
    balance,
    streak,
    claimedToday,
    nextResetAt,
    rewardProduct,
    soundOn,
    busy,
  );

  @override
  String toString() =>
      'CheckInViewState(signedIn: $signedIn, balance: $balance, '
      'streak: $streak, claimedToday: $claimedToday, busy: $busy)';
}

/// Hasil satu klaim yang berhasil.
@immutable
final class CheckInClaimResult {
  /// Membuat hasil klaim.
  const CheckInClaimResult({
    required this.award,
    required this.balance,
    this.product,
  });

  /// Hadiah dari aturan murni (streak baru, Kelopak, bonus, hak produk).
  final CheckInAward award;

  /// Saldo setelah klaim.
  final int balance;

  /// Produk yang dimenangkan saat `award.productEntitled`, bila host tahu
  /// produknya.
  final CheckInRewardProduct? product;
}

/// Jembatan halaman ke sumber data. Halaman hanya membaca [state] dan
/// memanggil aksi; host yang menentukan data datang dari mana.
///
/// Panggil `notifyListeners` tiap kali [state] berubah.
abstract class CheckInController extends ChangeNotifier {
  /// Keadaan terkini.
  CheckInViewState get state;

  /// Jam yang dipakai hitung mundur ke 00.00 WIB.
  DateTime now() => DateTime.now();

  /// Memuat ulang keadaan (mis. saat hari WIB berganti).
  Future<void> refresh();

  /// Mengklaim hari ini. Mengembalikan `null` bila hari ini sudah diklaim
  /// atau pengguna belum masuk; melempar bila klaim gagal dikirim.
  Future<CheckInClaimResult?> claim();

  /// Membuka halaman Masuk.
  void openLogin();

  /// Membuka katalog belanja.
  void openShop();

  /// Membuka keranjang (hadiah produk menunggu di sana).
  void openCart();

  /// Membuka detail produk [code].
  void openProduct(String code);

  /// Membuka syarat dan ketentuan lengkap.
  void openTerms();

  /// Memutar suara [cue]. Getar sudah ditangani halaman.
  void playCue(GameCue cue) {}

  /// Menyalakan atau mematikan suara host.
  void setSoundOn(bool value) {}
}
