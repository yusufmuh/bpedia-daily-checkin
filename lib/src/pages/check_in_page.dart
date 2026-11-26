import 'dart:async';

import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_engine.dart';
import '../check_in_format.dart';
import '../check_in_view.dart';
import '../kit/kit.dart';
import '../widgets/check_in_how_to.dart';
import '../widgets/check_in_month_grid.dart';
import '../widgets/check_in_tones.dart';
import '../widgets/lively_pose.dart';

/// Halaman game Check-in Harian.
///
/// Mengikuti rancangan desainer owner: hero pesta dengan Bipy bergerak,
/// kartu tiga aturan, kisi 30 hari di lipatan pertama, ketentuan, dan satu
/// tombol permen yang menempel di bawah.
/// Halaman hanya mengenal [controller]: keadaan dibaca dari
/// `controller.state`, semua aksi (klaim, masuk, buka produk) lewat metodenya.
class CheckInPage extends StatefulWidget {
  /// Membuat halaman di atas [controller].
  const CheckInPage({
    super.key,
    required this.controller,
    this.onBack,
    this.showResultSheet = true,
  });

  /// Sumber keadaan dan penerima aksi.
  final CheckInController controller;

  /// Pengganti tombol kembali bawaan (`Navigator.maybePop`).
  final VoidCallback? onBack;

  /// Menutup tiap klaim dengan lembar hasil. Matikan bila host menampilkan
  /// hasilnya sendiri.
  final bool showResultSheet;

  /// Kunci tombol utama di bar bawah.
  static const Key primaryButtonKey = ValueKey<String>('check-in-primary');

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final ScrollController _scroll = ScrollController();
  final SpriteController _bipy = SpriteController();
  final ConfettiController _confetti = ConfettiController();
  final CoinFlightController _flight = CoinFlightController();
  final GlobalKey _balanceKey = GlobalKey(debugLabel: 'check-in-balance');
  final GlobalKey _todayKey = GlobalKey(debugLabel: 'check-in-today');

  Timer? _clock;
  DateTime? _refreshedFor;
  bool _claiming = false;
  int? _heldBalance;
  bool _precached = false;

  CheckInController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onState);
    _syncClock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      unawaited(CheckInSprites.jump.precache(context));
    }
  }

  @override
  void didUpdateWidget(CheckInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onState);
      _controller.addListener(_onState);
      _syncClock();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onState);
    _clock?.cancel();
    _scroll.dispose();
    _bipy.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onState() {
    _syncClock();
    if (mounted) setState(() {});
  }

  /// Hitung mundur hanya berdetak selama hari ini sudah diklaim.
  void _syncClock() {
    final CheckInViewState state = _controller.state;
    final bool needed =
        state.signedIn && state.claimedToday && state.nextResetAt != null;
    if (!needed) {
      _clock?.cancel();
      _clock = null;
      return;
    }
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    final DateTime? resetAt = _controller.state.nextResetAt;
    if (resetAt != null &&
        !resetAt.isAfter(_controller.now()) &&
        _refreshedFor != resetAt) {
      _refreshedFor = resetAt;
      unawaited(_controller.refresh());
    }
    setState(() {});
  }

  Duration? get _untilReset {
    final DateTime? resetAt = _controller.state.nextResetAt;
    if (resetAt == null) return null;
    final Duration left = resetAt.difference(_controller.now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _pause(int milliseconds) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  void _pokeBipy() {
    emitCue(_controller.playCue, GameCue.tap);
    _bipy.play(CheckInSprites.jump);
  }

  void _openLogin() {
    emitCue(_controller.playCue, GameCue.tap);
    _controller.openLogin();
  }

  void _fail() {
    emitCue(_controller.playCue, GameCue.softError);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Check-in belum berhasil. Periksa koneksimu, lalu coba lagi.',
          ),
        ),
      );
  }

  Future<void> _claim() async {
    final CheckInViewState before = _controller.state;
    if (_claiming || before.busy || before.claimedToday) return;
    final bool reduce = reduceMotionOf(context);
    setState(() {
      _claiming = true;
      _heldBalance = before.balance;
    });
    emitCue(_controller.playCue, GameCue.tap);
    try {
      if (_scroll.hasClients && _scroll.offset > 1) {
        if (reduce) {
          _scroll.jumpTo(0);
        } else {
          await _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      }
      final CheckInClaimResult? result;
      try {
        result = await _controller.claim();
      } on Object {
        _fail();
        return;
      }
      if (!mounted) return;
      if (result == null) {
        _fail();
        return;
      }
      final CheckInAward award = result.award;
      final bool bonus = award.bonusKelopak > 0;

      // Ubin hari ini membal sendiri saat keadaan berubah; 100 ms kemudian
      // koin menyembur ke chip saldo.
      if (!reduce) await _pause(100);
      if (!mounted) return;
      _bipy.play(CheckInSprites.jump);
      _confetti.fire(
        origin: const Alignment(0.5, -0.62),
        count: 36,
        power: 0.75,
      );
      await _flight.fly(
        fromKey: _todayKey,
        toKey: _balanceKey,
        onFirstArrive: () {
          if (mounted) setState(() => _heldBalance = null);
          emitCue(_controller.playCue, GameCue.claim);
        },
      );
      if (!mounted) return;
      if (bonus) {
        _confetti.fire(style: ConfettiStyle.cannons);
        emitCue(_controller.playCue, GameCue.bonus);
      }
      if (!reduce) await _pause(bonus ? 720 : 520);
      if (!mounted) return;
      setState(() => _heldBalance = null);
      if (award.productEntitled) {
        emitCue(_controller.playCue, GameCue.winProduct);
      }
      if (widget.showResultSheet) await _showResult(result);
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
          _heldBalance = null;
        });
      }
    }
  }

  Future<void> _showResult(CheckInClaimResult result) {
    final CheckInAward award = result.award;
    final CheckInRewardProduct? product =
        result.product ?? _controller.state.rewardProduct;
    return showResultSheet<void>(
      context,
      builder: (BuildContext sheet) {
        void close() => Navigator.pop(sheet);
        void shop() {
          close();
          _controller.openShop();
        }

        void wheel() {
          close();
          _controller.openWheel();
        }

        final ({String label, VoidCallback action}) follow =
            _controller.wheelReady
            ? (label: 'Lanjut putar Roda Sabtu', action: wheel)
            : (label: 'Belanja sekarang', action: shop);

        if (award.productEntitled) {
          return ResultSheet(
            ribbon: 'Selamat!',
            title: '30 hari tanpa putus',
            pill: '1 produk gratis',
            art: product == null
                ? const Image(image: CheckInArt.giftOpen)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD36B),
                        width: 4,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x40B3164B),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox.square(
                        dimension: 160,
                        child: Image(image: product.image, fit: BoxFit.cover),
                      ),
                    ),
                  ),
            companion: const LivelyPose(
              image: CheckInArt.poseStarJump,
              height: 116,
              energy: 2,
            ),
            caption: product?.name ?? 'Produk gratis pilihan Bpedia',
            message:
                'Hadiah masuk ke keranjang dan dikirim bersama pesanan '
                'berikutnya. ${balanceSentence(result.balance)}',
            primaryLabel: 'Lihat keranjang',
            onPrimary: () {
              close();
              _controller.openCart();
            },
            secondaryLabel: follow.label,
            onSecondary: follow.action,
          );
        }
        final bool bonus = award.bonusKelopak > 0;
        return ResultSheet(
          ribbon: bonus ? 'Bonus!' : null,
          title: bonus
              ? 'Bonus 7 hari beruntun!'
              : 'Check-in hari ke-${award.streak} berhasil!',
          pill: 'Streak ${award.streak} hari',
          art: Image(image: bonus ? CheckInArt.giftOpen : CheckInArt.coin),
          companion: LivelyPose(
            image: bonus ? CheckInArt.poseRose : CheckInArt.poseStar,
            height: 120,
            energy: bonus ? 1.6 : 1,
          ),
          amount: award.totalKelopak,
          amountSuffix: ' Kelopak',
          message: bonus
              ? 'Termasuk bonus +${award.bonusKelopak} Kelopak. '
                    '${balanceSentence(result.balance)}'
              : balanceSentence(result.balance),
          note: nextBonusNote(award.streak),
          primaryLabel: 'Mantap',
          primaryVariant: CandyVariant.gold,
          onPrimary: close,
          secondaryLabel: follow.label,
          onSecondary: follow.action,
        );
      },
    );
  }

  Widget _bottomBar(CheckInViewState state) {
    if (!state.signedIn) {
      return CandyButton(
        key: CheckInPage.primaryButtonKey,
        label: 'Masuk untuk check-in',
        sublabel: 'Klaim +1 Kelopak tiap hari',
        icon: const Icon(Icons.login_rounded, size: 24, color: Colors.white),
        onPressed: _openLogin,
      );
    }
    if (state.claimedToday && !_claiming) {
      final Duration? left = _untilReset;
      return CandyButton(
        key: CheckInPage.primaryButtonKey,
        label: 'Kembali besok',
        sublabel: left == null
            ? 'Check-in buka lagi 00.00 WIB'
            : 'Check-in lagi dalam ${countdownClock(left)}',
        semanticLabel: left == null
            ? 'Kembali besok, check-in buka lagi pukul 00.00 WIB'
            : 'Kembali besok, check-in buka lagi dalam '
                  '${countdownSpoken(left)}',
        icon: const Icon(Icons.check_circle_rounded, size: 24),
        variant: CandyVariant.tonal,
        shine: false,
        onPressed: null,
      );
    }
    final String reward = state.todayGrantsProduct
        ? '+${state.todayKelopak} Kelopak dan 1 produk gratis'
        : state.todayIsBonus
        ? '+${state.todayKelopak} Kelopak, termasuk bonus +3'
        : '+${state.todayKelopak} Kelopak hari ini';
    return CandyButton(
      key: CheckInPage.primaryButtonKey,
      label: 'Check-in sekarang',
      sublabel: reward,
      icon: const Image(image: CheckInArt.coin, width: 30, height: 30),
      pulse: !_claiming,
      busy: _claiming || state.busy,
      onPressed: _claim,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final CheckInViewState state = _controller.state;
    final bool? soundOn = state.soundOn;
    final CheckInRewardProduct? product = state.rewardProduct;
    final TextStyle body = theme.textTheme.bodyMedium ?? const TextStyle();
    // Selama klaim berjalan strip sudah berubah, tetapi saldo ditahan sampai
    // koin pertama tiba.
    final int balance = _heldBalance ?? state.balance;

    final String streakLine = streakMessage(state);
    final int split = streakLine.indexOf(' · ');
    final TextStyle subStyle = body.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );

    final Widget hero = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                // Judul pajangan dibatasi 1,6x supaya kata tidak terpotong di
                // samping Bipy; teks lain tetap ikut skala penuh.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.6,
                  child: Text(
                    'Check-in Harian',
                    style: body.copyWith(
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const <Shadow>[
                        Shadow(
                          color: Color(0xCC9E1242),
                          offset: Offset(0, 1.5),
                        ),
                        Shadow(
                          color: Color(0x596B1439),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                split < 0
                    ? TextSpan(text: streakLine)
                    : TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: streakLine.substring(0, split),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: streakLine.substring(split)),
                        ],
                      ),
                style: subStyle,
              ),
              const SizedBox(height: 10),
              if (state.signedIn)
                BalanceChip(
                  key: _balanceKey,
                  value: balance,
                  coin: CheckInArt.coin,
                  suffix: ' Kelopak',
                )
              else
                GlassChip(
                  key: _balanceKey,
                  strong: true,
                  label: 'Masuk untuk kumpulkan Kelopak',
                  leading: const Icon(Icons.login_rounded),
                  onTap: _openLogin,
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Pressable(
          onTap: _pokeBipy,
          semanticLabel: 'Bipy',
          pressedScale: 0.95,
          child: SpriteAnimation(
            spec: CheckInSprites.idle,
            controller: _bipy,
            height: 140,
          ),
        ),
      ],
    );

    const Widget rulesCard = FestivePanel(
      padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: CheckInHowTo(),
    );

    final int currentDay = state.claimedToday
        ? state.monthDay
        : state.monthDay + 1;
    final Widget monthPanel = FestivePanel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CheckInCycleHeader(
            day: currentDay,
            product: product,
            onOpenProduct: product == null
                ? null
                : () => _controller.openProduct(product.code),
          ),
          const SizedBox(height: 12),
          CheckInMonthGrid(
            day: state.monthDay,
            claimedToday: state.claimedToday,
            cycleStart: state.monthCycleStart,
            rewardImage: product?.image,
            todayAnchorKey: _todayKey,
            stampLatest: _claiming,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: tones.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Produk dikirim bersama pesanan belanjamu, tanpa ongkir '
                  'tambahan.',
                  style: body.copyWith(
                    fontSize: 12,
                    height: 17 / 12,
                    color: tones.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final Widget termsPanel = FestivePanel(
      title: 'Ketentuan',
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CheckInTerms(onOpenTerms: _controller.openTerms),
    );

    return ConfettiBurst(
      controller: _confetti,
      child: CoinFlight(
        controller: _flight,
        image: CheckInArt.coin,
        child: GameScaffold(
          title: 'Check-in Harian',
          onBack: widget.onBack,
          scrollController: _scroll,
          backdrop: _HeroBackdrop(scroll: _scroll),
          heroPadding: const EdgeInsets.fromLTRB(16, 4, 12, 16),
          actions: <Widget>[
            if (soundOn != null)
              GameBarAction(
                icon: soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                tooltip: soundOn ? 'Matikan suara' : 'Nyalakan suara',
                onPressed: () => _controller.setSoundOn(!soundOn),
              ),
            GameBarAction.text(
              label: 'Aturan',
              onPressed: () => showCheckInRulesSheet(
                context,
                onOpenTerms: _controller.openTerms,
              ),
            ),
          ],
          hero: hero,
          slivers: <Widget>[
            const SliverToBoxAdapter(child: rulesCard),
            SliverToBoxAdapter(child: monthPanel),
            SliverToBoxAdapter(child: termsPanel),
          ],
          bottomBar: _bottomBar(state),
        ),
      ),
    );
  }
}

/// Satu hiasan melayang di hero.
@immutable
class _Float {
  const _Float(
    this.image,
    this.alignment,
    this.size, {
    this.parallax = 0.2,
    this.phase = 0,
    this.turn = 0,
    this.opacity = 1,
  });

  final ImageProvider image;
  final Alignment alignment;
  final double size;

  /// Bagian gulir yang diikuti hiasan (0 = diam, 1 = ikut isi).
  final double parallax;
  final double phase;
  final double turn;
  final double opacity;
}

const List<_Float> _floats = <_Float>[
  _Float(
    CheckInArt.coin,
    Alignment(0.5, -0.5),
    34,
    parallax: 0.45,
    phase: 0.1,
    turn: -0.25,
  ),
  _Float(
    CheckInArt.coin,
    Alignment(0.97, -0.5),
    26,
    parallax: 0.3,
    phase: 0.55,
    turn: 0.3,
  ),
  _Float(
    CheckInArt.stickerFlowerPink,
    Alignment(0.56, 0.22),
    22,
    parallax: 0.25,
    phase: 0.35,
    turn: -0.2,
  ),
  _Float(
    CheckInArt.stickerSparkle,
    Alignment(0.2, -0.88),
    18,
    parallax: 0.15,
    phase: 0.7,
    opacity: 0.9,
  ),
  _Float(
    CheckInArt.stickerStar,
    Alignment(0.99, 0.3),
    20,
    parallax: 0.5,
    phase: 0.2,
    turn: 0.3,
  ),
];

/// Latar hero: gradasi pesta dengan koin 3D dan stiker yang melayang serta
/// bergeser paralaks terhadap gulir.
class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Kilau acak bawaan dimatikan karena bisa jatuh di atas judul;
        // stiker kilau sendiri ditempatkan jauh dari teks.
        const FestiveHero(sparkles: false),
        for (final _Float item in _floats)
          Align(
            alignment: item.alignment,
            child: AnimatedBuilder(
              animation: scroll,
              builder: (BuildContext context, Widget? child) {
                final double offset = scroll.hasClients ? scroll.offset : 0;
                return Transform.translate(
                  offset: Offset(0, offset * item.parallax),
                  child: child,
                );
              },
              child: ExcludeSemantics(
                child: Bobbing(
                  amplitude: 5,
                  phase: item.phase,
                  tilt: 0.08,
                  child: Opacity(
                    opacity: item.opacity,
                    child: Transform.rotate(
                      angle: item.turn,
                      child: Image(
                        image: item.image,
                        width: item.size,
                        height: item.size,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
