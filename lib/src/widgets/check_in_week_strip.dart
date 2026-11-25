import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_engine.dart';
import '../check_in_format.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Strip "Minggu ini": tujuh ubin hari dengan seni koin 3D dan nilai hadiah.
///
/// Ubin ke-7 lebih lebar dan berisi kotak hadiah (+4 dengan pita "Bonus").
/// Ubin hari ini berbingkai aksen dan berdenyut; saat [claimedToday] berubah
/// menjadi `true`, ubin itu membal, lencana centang muncul, dan pada hari
/// ke-7 kotak hadiah bergoyang lalu terbuka. Pada huruf besar ubin turun ke
/// baris berikutnya supaya label tidak mengecil.
class CheckInWeekStrip extends StatefulWidget {
  /// Membuat strip dengan [filled] ubin terisi (dibatasi 0..7).
  const CheckInWeekStrip({
    super.key,
    required this.filled,
    required this.claimedToday,
    this.todayAnchorKey,
  });

  /// Jumlah ubin terisi.
  final int filled;

  /// Hari ini sudah diklaim (tidak ada ubin "hari ini").
  final bool claimedToday;

  /// Kunci yang ditempel ke seni ubin hari ini (atau ubin yang baru saja
  /// diklaim) sebagai titik berangkat koin terbang.
  final GlobalKey? todayAnchorKey;

  /// Skala puncak denyut ubin hari ini.
  static const double pulseScale = 1.06;

  /// Durasi animasi stempel klaim.
  static const Duration stampDuration = Duration(milliseconds: 1400);

  @override
  State<CheckInWeekStrip> createState() => _CheckInWeekStripState();
}

class _CheckInWeekStripState extends State<CheckInWeekStrip>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: CheckInWeekStrip.stampDuration,
    value: 1,
  );
  late final Animation<double> _pulseScale = Tween<double>(
    begin: 1,
    end: CheckInWeekStrip.pulseScale,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  int? _stampIndex;

  int get _filled => widget.filled.clamp(0, CheckInRules.bonusEvery);

  int? get _todayIndex =>
      !widget.claimedToday && _filled < CheckInRules.bonusEvery
      ? _filled
      : null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(CheckInWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int before = oldWidget.filled.clamp(0, CheckInRules.bonusEvery);
    final bool justClaimed =
        !oldWidget.claimedToday &&
        widget.claimedToday &&
        _filled == before + 1;
    if (justClaimed && !reduceMotionOf(context)) {
      _stampIndex = _filled - 1;
      _stamp.forward(from: 0);
    } else if (!widget.claimedToday) {
      _stampIndex = null;
      _stamp.value = 1;
    }
    _syncPulse();
  }

  void _syncPulse() {
    final bool run = _todayIndex != null && !reduceMotionOf(context);
    if (run) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextStyle base = theme.textTheme.labelSmall ?? const TextStyle();
    final TextStyle labelStyle = base.copyWith(
      fontSize: 10,
      height: 14 / 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final TextStyle valueStyle = base.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
    final int? today = _todayIndex;
    // Pita "Hari ini" dan "Bonus" ikut membesar bersama teks; isi ubin turun
    // sejauh itu supaya angka di bawahnya tidak tertutup.
    final double topInset = math.max(9, scaler.scale(14) - 5);
    final int? anchor = widget.claimedToday ? _filled - 1 : today;

    Widget tile(int index) {
      final Widget child = _DayTile(
        day: index + 1,
        claimed: index < _filled,
        today: index == today,
        tones: tones,
        labelStyle: labelStyle,
        valueStyle: valueStyle,
        topInset: topInset,
        pulse: index == today ? _pulseScale : null,
        glow: index == today ? _pulse : null,
        stamp: index == _stampIndex ? _stamp : null,
        artKey: index == anchor ? widget.todayAnchorKey : null,
      );
      return Semantics(
        container: true,
        label: weekTileSemantics(
          day: index + 1,
          filled: _filled,
          claimedToday: widget.claimedToday,
        ),
        child: ExcludeSemantics(child: child),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 4;
        final double labelWidth = _textWidth(
          'Hari 7',
          labelStyle,
          scaler,
          Directionality.of(context),
        );
        final double minTile = math.max(36, labelWidth + 6);
        final double width = constraints.maxWidth;
        final bool oneRow = width >= minTile * 7.35 + gap * 6;
        if (oneRow) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < 7; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(flex: i == 6 ? 135 : 100, child: tile(i)),
                ],
              ],
            ),
          );
        }
        final int perRow = ((width + gap) / (minTile + gap)).floor().clamp(
          1,
          4,
        );
        final List<Widget> rows = <Widget>[];
        for (int start = 0; start < 7; start += perRow) {
          final int end = math.min(7, start + perRow);
          final int spare = perRow - (end - start);
          rows.add(
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = start; i < end; i++) ...<Widget>[
                    if (i > start) const SizedBox(width: gap),
                    Expanded(
                      flex: i == 6 ? 1 + spare : 1,
                      child: tile(i),
                    ),
                  ],
                  if (spare > 0 && end != 7) ...<Widget>[
                    const SizedBox(width: gap),
                    Spacer(flex: spare),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}

double _textWidth(
  String text,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.claimed,
    required this.today,
    required this.tones,
    required this.labelStyle,
    required this.valueStyle,
    required this.topInset,
    required this.pulse,
    required this.glow,
    required this.stamp,
    required this.artKey,
  });

  final int day;
  final bool claimed;
  final bool today;
  final CheckInTones tones;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final double topInset;
  final Animation<double>? pulse;
  final Animation<double>? glow;
  final AnimationController? stamp;
  final GlobalKey? artKey;

  bool get _bonus => day == CheckInRules.bonusEvery;

  BoxDecoration _decoration(double glowAmount) {
    final BorderRadius radius = BorderRadius.circular(12);
    if (today) {
      return BoxDecoration(
        color: _bonus ? tones.goldTint : tones.surface,
        borderRadius: radius,
        border: Border.all(color: tones.brand, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tones.brand.withValues(alpha: 0.18 + 0.22 * glowAmount),
            blurRadius: 8 + 10 * glowAmount,
            spreadRadius: 1 * glowAmount,
          ),
        ],
      );
    }
    if (_bonus) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tones.dark
              ? const <Color>[Color(0xFF4A3608), Color(0xFF3A2C0A)]
              : const <Color>[Color(0xFFFFF7E0), Color(0xFFFFE7A8)],
        ),
        borderRadius: radius,
        border: Border.all(color: tones.gold, width: 1.5),
      );
    }
    if (claimed) {
      return BoxDecoration(
        color: tones.goldTint,
        borderRadius: radius,
        border: Border.all(color: tones.goldLine),
      );
    }
    return BoxDecoration(
      color: tones.muted,
      borderRadius: radius,
      border: Border.all(color: tones.line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AnimationController? stamp = this.stamp;
    final Animation<double>? glow = this.glow;
    final Color valueColor = today
        ? tones.brand
        : (claimed || _bonus)
        ? tones.onGoldTint
        : tones.textMuted;
    final int kelopak =
        CheckInRules.dailyKelopak + (_bonus ? CheckInRules.bonusKelopak : 0);

    Widget body(double glowAmount, double stampValue) {
      return DecoratedBox(
        decoration: _decoration(glowAmount),
        child: Padding(
          padding: EdgeInsets.fromLTRB(2, topInset, 2, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '+$kelopak',
                maxLines: 1,
                softWrap: false,
                style: valueStyle.copyWith(color: valueColor),
              ),
              const SizedBox(height: 2),
              SizedBox(
                key: artKey,
                height: 34,
                child: _TileArt(
                  bonus: _bonus,
                  claimed: claimed,
                  faded: !claimed && !today,
                  stamp: stampValue,
                  tones: tones,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Hari $day',
                maxLines: 1,
                softWrap: false,
                style: labelStyle.copyWith(
                  color: today ? tones.brand : tones.textMuted,
                  fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget tile;
    if (stamp != null) {
      tile = AnimatedBuilder(
        animation: stamp,
        builder: (BuildContext context, Widget? _) {
          final double t = stamp.value;
          final double bounce = _bounce(
            (t * CheckInWeekStrip.stampDuration.inMilliseconds / 420).clamp(
              0.0,
              1.0,
            ),
          );
          return Transform.scale(scale: bounce, child: body(0, t));
        },
      );
    } else if (glow != null) {
      tile = AnimatedBuilder(
        animation: glow,
        builder: (BuildContext context, Widget? _) => body(glow.value, 1),
      );
    } else {
      tile = body(0, 1);
    }
    final Animation<double>? pulse = this.pulse;
    if (pulse != null) tile = ScaleTransition(scale: pulse, child: tile);

    final Widget? topper = today
        ? _TodayPill(tones: tones)
        : _bonus
        ? const FestiveRibbon(label: 'Bonus')
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        tile,
        if (topper != null)
          Positioned(
            top: -9,
            left: -8,
            right: -8,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: topper),
            ),
          ),
        if (stamp != null && _bonus)
          Positioned(
            top: -6,
            left: -20,
            right: -20,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: stamp,
                builder: (BuildContext context, Widget? child) {
                  final double t = ((stamp.value - 0.46) / 0.54).clamp(
                    0.0,
                    1.0,
                  );
                  final double fade = t <= 0
                      ? 0
                      : t < 0.2
                      ? t / 0.2
                      : t > 0.8
                      ? (1 - t) / 0.2
                      : 1;
                  return Opacity(
                    opacity: fade,
                    child: Transform.translate(
                      offset: Offset(0, -34 * Curves.easeOutCubic.transform(t)),
                      child: child,
                    ),
                  );
                },
                child: Center(child: _BonusFloat(tones: tones)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Membal 1 → 1,12 → 1 untuk [t] 0..1.
double _bounce(double t) {
  if (t >= 1) return 1;
  return 1 + 0.12 * math.sin(math.pi * Curves.easeOut.transform(t));
}

class _TileArt extends StatelessWidget {
  const _TileArt({
    required this.bonus,
    required this.claimed,
    required this.faded,
    required this.stamp,
    required this.tones,
  });

  final bool bonus;
  final bool claimed;
  final bool faded;

  /// 0..1 selama animasi stempel; 1 = diam.
  final double stamp;
  final CheckInTones tones;

  @override
  Widget build(BuildContext context) {
    final double size = bonus ? 34 : 30;
    // Hari bonus: kado bergoyang tiga kali (0..0,43) lalu terbuka.
    final bool opened = claimed && (!bonus || stamp >= 0.43);
    Widget art = Image(
      image: bonus
          ? (opened ? CheckInArt.giftOpen : CheckInArt.giftClosed)
          : CheckInArt.coin,
      width: size,
      height: size,
    );
    if (faded && !bonus) {
      art = Opacity(
        opacity: 0.8,
        child: ColorFiltered(colorFilter: saturationFilter(0.45), child: art),
      );
    }
    if (bonus && stamp < 1) {
      if (stamp < 0.43) {
        final double wobble =
            math.sin(stamp / 0.43 * math.pi * 6) * 0.16 * (1 - stamp / 0.43 / 2);
        art = Transform.rotate(angle: wobble, child: art);
      } else {
        final double pop = ((stamp - 0.43) / 0.25).clamp(0.0, 1.0);
        art = Transform.scale(
          scale: 1 + 0.3 * math.sin(math.pi * pop),
          child: art,
        );
      }
    }
    final double badge = claimed
        ? Curves.elasticOut.transform(
            ((stamp - (bonus ? 0.45 : 0.06)) / 0.3).clamp(0.0, 1.0),
          )
        : 0;
    return SizedBox(
      width: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          art,
          if (badge > 0)
            Positioned(
              right: -2,
              bottom: -1,
              child: Transform.scale(
                scale: badge,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tones.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tones.dark ? tones.goldTint : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: 16,
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: tones.onSuccess,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.tones});

  final CheckInTones tones;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: tones.brand,
        shape: const StadiumBorder(),
        shadows: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          'Hari ini',
          maxLines: 1,
          softWrap: false,
          style: base.copyWith(
            fontSize: 9,
            height: 13 / 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: tones.onBrand,
          ),
        ),
      ),
    );
  }
}

class _BonusFloat extends StatelessWidget {
  const _BonusFloat({required this.tones});

  final CheckInTones tones;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    return DecoratedBox(
      decoration: const ShapeDecoration(
        gradient: FestivePalette.goldSheen,
        shape: StadiumBorder(),
        shadows: <BoxShadow>[
          BoxShadow(color: Color(0x40C98A0A), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          '+${CheckInRules.bonusKelopak} bonus',
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: base.copyWith(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w800,
            color: FestivePalette.onGold,
          ),
        ),
      ),
    );
  }
}
