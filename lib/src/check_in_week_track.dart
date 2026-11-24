import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'check_in_engine.dart';

part 'tulip_painter.dart';

/// The 7-day track of Check-in Harian, themed "Kebun Bipy".
///
/// Each claimed day is a bloomed tulip. While today is not claimed its slot
/// shows an outlined, gently pulsing bud with [currencyIcon]; later days show
/// faded buds. Slot 7 carries the bonus ([bonusIcon], fallback
/// [Icons.card_giftcard]) and a "+3" pill. Every slot exposes its own
/// semantics label, e.g. "Hari 4, hari ini, belum check-in".
///
/// Use [filledInWeek] for [filled]. The pulse stops when
/// [MediaQuery.disableAnimationsOf] is true.
class CheckInWeekTrack extends StatelessWidget {
  /// Creates the 7-day track.
  const CheckInWeekTrack({
    super.key,
    required this.filled,
    required this.claimedToday,
    required this.currencyIcon,
    this.bonusIcon,
  });

  /// Bloomed slots, 0..7 (values outside are clamped).
  final int filled;

  /// Whether today is already claimed. When false, slot `filled + 1` is today.
  final bool claimedToday;

  /// Kelopak token shown at 16 dp inside today's slot.
  final Widget currencyIcon;

  /// Gift artwork of slot 7; [Icons.card_giftcard] when null.
  final Widget? bonusIcon;

  @override
  Widget build(BuildContext context) {
    const int days = CheckInRules.bonusEvery;
    final int bloomed = filled.clamp(0, days);
    final int? todayIndex = claimedToday || bloomed == days ? null : bloomed;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        for (int index = 0; index < days; index++)
          Expanded(
            child: _DaySlot(
              day: index + 1,
              status: index < bloomed
                  ? _SlotStatus.claimed
                  : index == todayIndex
                  ? _SlotStatus.today
                  : _SlotStatus.upcoming,
              isBonusDay: index == days - 1,
              currencyIcon: currencyIcon,
              bonusIcon: bonusIcon,
            ),
          ),
      ],
    );
  }
}

enum _SlotStatus { claimed, today, upcoming }

class _DaySlot extends StatelessWidget {
  const _DaySlot({
    required this.day,
    required this.status,
    required this.isBonusDay,
    required this.currencyIcon,
    required this.bonusIcon,
  });

  final int day;
  final _SlotStatus status;
  final bool isBonusDay;
  final Widget currencyIcon;
  final Widget? bonusIcon;

  String get _semanticsLabel {
    final String state = switch (status) {
      _SlotStatus.claimed => 'sudah check-in',
      _SlotStatus.today => 'hari ini, belum check-in',
      _SlotStatus.upcoming => 'belum',
    };
    final String bonus = isBonusDay
        ? ', bonus ${CheckInRules.bonusKelopak} Kelopak'
        : '';
    return 'Hari $day, $state$bonus';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: switch (status) {
        _SlotStatus.claimed => scheme.onSurface,
        _SlotStatus.today => scheme.secondary,
        _SlotStatus.upcoming => scheme.onSurfaceVariant,
      },
      fontWeight: status == _SlotStatus.today ? FontWeight.w700 : null,
    );
    final Widget tile = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 64),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: _SlotTile(
          status: status,
          isBonusDay: isBonusDay,
          currencyIcon: currencyIcon,
          bonusIcon: bonusIcon,
        ),
      ),
    );
    return Semantics(
      container: true,
      label: _semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (status == _SlotStatus.today) _Pulse(child: tile) else tile,
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Hari $day', maxLines: 1, style: labelStyle),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.status,
    required this.isBonusDay,
    required this.currencyIcon,
    required this.bonusIcon,
  });

  final _SlotStatus status;
  final bool isBonusDay;
  final Widget currencyIcon;
  final Widget? bonusIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool claimed = status == _SlotStatus.claimed;
    final Color fill = claimed
        ? scheme.primaryContainer
        : isBonusDay
        ? scheme.tertiaryContainer
        : status == _SlotStatus.today
        ? scheme.surfaceContainerLowest
        : scheme.surfaceContainer;
    final Widget art = !claimed && isBonusDay
        ? _BonusArt(icon: bonusIcon)
        : CustomPaint(
            painter: _TulipPainter(
              stage: claimed ? _TulipStage.bloom : _TulipStage.bud,
              palette: status == _SlotStatus.upcoming
                  ? _TulipPalette.faded(scheme)
                  : _TulipPalette.vivid(scheme),
            ),
            child: const SizedBox.expand(),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: status == _SlotStatus.today
            ? Border.all(color: scheme.primary, width: 2)
            : null,
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Column(
                children: <Widget>[
                  Expanded(child: art),
                  if (isBonusDay && !claimed) const _BonusPill(),
                ],
              ),
            ),
          ),
          if (isBonusDay && claimed)
            const Positioned(
              left: 2,
              right: 2,
              bottom: 2,
              child: Center(child: _BonusPill()),
            ),
          if (claimed)
            const PositionedDirectional(top: 3, end: 3, child: _CheckBadge())
          else if (status == _SlotStatus.today)
            PositionedDirectional(
              top: 3,
              end: 3,
              child: _SizedArt(dimension: 16, child: currencyIcon),
            ),
        ],
      ),
    );
  }
}

class _BonusArt extends StatelessWidget {
  const _BonusArt({required this.icon});

  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: IconTheme.merge(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          child: _SizedArt(
            dimension: 26,
            child: icon ?? const Icon(Icons.card_giftcard),
          ),
        ),
      ),
    );
  }
}

class _BonusPill extends StatelessWidget {
  const _BonusPill();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: scheme.tertiary,
              shape: const StadiumBorder(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: Text(
                '+${CheckInRules.bonusKelopak}',
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onTertiary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primaryContainer, width: 1.5),
      ),
      child: SizedBox.square(
        dimension: 16,
        child: Icon(Icons.check, size: 11, color: scheme.onPrimary),
      ),
    );
  }
}

/// Gives host artwork a fixed square box; [Icon]s default to that size.
class _SizedArt extends StatelessWidget {
  const _SizedArt({required this.dimension, required this.child});

  final double dimension;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(size: dimension),
      child: SizedBox.square(dimension: dimension, child: child),
    );
  }
}

/// Breathes [child] between 100% and 106% every 1.2 s, unless the platform
/// asks to reduce motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    animationBehavior: AnimationBehavior.preserve,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.06,
  ).animate(_curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.reset();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
