import 'check_in_engine.dart';
import 'check_in_view.dart';
import 'kit/game_cue.dart';
import 'wib_calendar.dart';

/// [CheckInController] di memori untuk `example/`, tes, dan pratinjau.
///
/// Memakai aturan murni yang sama dengan server. Hari WIB bisa digeser
/// dengan [advanceDays] untuk mencoba streak tanpa menunggu tengah malam.
class LocalCheckInController extends CheckInController {
  /// Membuat pengendali lokal. [streak] dan [claimedToday] menyusun riwayat
  /// awal: `streak: 3, claimedToday: false` berarti tiga hari terakhir
  /// sampai kemarin sudah diklaim.
  LocalCheckInController({
    DateTime Function()? clock,
    bool signedIn = true,
    int balance = 0,
    int streak = 0,
    bool claimedToday = false,
    CheckInRewardProduct? rewardProduct,
    bool? soundOn = true,
    this.latency = Duration.zero,
    this.failNextClaim = false,
  }) : _clock = clock ?? DateTime.now,
       _signedIn = signedIn,
       _balance = balance,
       _rewardProduct = rewardProduct,
       _soundOn = soundOn {
    _seed(streak: streak, claimedToday: claimedToday);
  }

  final DateTime Function() _clock;

  /// Jeda buatan sebelum klaim selesai (meniru jaringan).
  Duration latency;

  /// Bila `true`, klaim berikutnya gagal sekali (untuk mencoba pesan galat).
  bool failNextClaim;

  bool _signedIn;
  int _balance;
  int _streak = 0;
  int? _lastClaimDay;
  int _dayOffset = 0;
  bool _busy = false;
  bool? _soundOn;
  CheckInRewardProduct? _rewardProduct;
  int _productsWon = 0;
  final List<String> _actions = <String>[];

  /// Hari WIB yang sedang berlaku (jam + geseran demo).
  int get today => wibDayOf(_clock()) + _dayOffset;

  /// Geseran hari demo terhadap jam.
  int get dayOffset => _dayOffset;

  /// Jumlah produk gratis yang sudah dimenangkan di sesi ini.
  int get productsWon => _productsWon;

  /// Catatan aksi keluar dan suara, urut waktu (mis. `openLogin`,
  /// `openProduct:P1`, `cue:claim`).
  List<String> get actions => List<String>.unmodifiable(_actions);

  @override
  DateTime now() => _clock();

  @override
  CheckInViewState get state {
    if (!_signedIn) {
      return CheckInViewState.guest(
        rewardProduct: _rewardProduct,
        soundOn: _soundOn,
      );
    }
    final int nextDay = wibDayOf(_clock()) + 1;
    return CheckInViewState.fromProgress(
      today: today,
      lastClaimDay: _lastClaimDay,
      storedStreak: _streak,
      balance: _balance,
      nextResetAt: DateTime.fromMillisecondsSinceEpoch(
        nextDay * Duration.millisecondsPerDay -
            7 * Duration.millisecondsPerHour,
        isUtc: true,
      ),
      rewardProduct: _rewardProduct,
      soundOn: _soundOn,
      busy: _busy,
    );
  }

  @override
  Future<void> refresh() async => notifyListeners();

  @override
  Future<CheckInClaimResult?> claim() async {
    if (!_signedIn || _busy) return null;
    if (latency > Duration.zero) {
      _busy = true;
      notifyListeners();
      await Future<void>.delayed(latency);
      _busy = false;
    }
    if (failNextClaim) {
      failNextClaim = false;
      notifyListeners();
      throw StateError('Klaim gagal (simulasi).');
    }
    final int day = today;
    final CheckInAward? award = evaluateCheckIn(
      today: day,
      lastClaimDay: _lastClaimDay,
      streak: _streak,
    );
    if (award == null) {
      notifyListeners();
      return null;
    }
    _lastClaimDay = day;
    _streak = award.streak;
    _balance += award.totalKelopak;
    if (award.productEntitled) _productsWon++;
    notifyListeners();
    return CheckInClaimResult(
      award: award,
      balance: _balance,
      product: award.productEntitled ? _rewardProduct : null,
    );
  }

  /// Menggeser hari WIB demo sebanyak [days] (boleh negatif).
  void advanceDays(int days) {
    _dayOffset += days;
    notifyListeners();
  }

  /// Menyusun ulang riwayat: [streak] hari beruntun, hari ini sudah atau
  /// belum diklaim. Saldo tidak berubah kecuali [balance] diisi.
  void seed({required int streak, required bool claimedToday, int? balance}) {
    _seed(streak: streak, claimedToday: claimedToday);
    if (balance != null) _balance = balance;
    notifyListeners();
  }

  void _seed({required int streak, required bool claimedToday}) {
    assert(streak >= 0, 'Streak tidak boleh negatif.');
    assert(!claimedToday || streak > 0, 'Sudah klaim berarti streak >= 1.');
    _streak = streak;
    _lastClaimDay = streak == 0 ? null : (claimedToday ? today : today - 1);
  }

  /// Sudah masuk (`true`) atau tamu (`false`).
  bool get signedIn => _signedIn;

  set signedIn(bool value) {
    if (_signedIn == value) return;
    _signedIn = value;
    notifyListeners();
  }

  /// Produk hadiah hari ke-30.
  CheckInRewardProduct? get rewardProduct => _rewardProduct;

  set rewardProduct(CheckInRewardProduct? value) {
    _rewardProduct = value;
    notifyListeners();
  }

  /// Kembali ke keadaan awal: tanpa riwayat, saldo 0, hari tidak digeser.
  void reset() {
    _streak = 0;
    _lastClaimDay = null;
    _balance = 0;
    _dayOffset = 0;
    _productsWon = 0;
    _actions.clear();
    notifyListeners();
  }

  @override
  void openLogin() => _actions.add('openLogin');

  @override
  void openShop() => _actions.add('openShop');

  @override
  void openCart() => _actions.add('openCart');

  @override
  void openProduct(String code) => _actions.add('openProduct:$code');

  @override
  void openTerms() => _actions.add('openTerms');

  @override
  void playCue(GameCue cue) => _actions.add('cue:${cue.name}');

  @override
  void setSoundOn(bool value) {
    _soundOn = value;
    notifyListeners();
  }
}
