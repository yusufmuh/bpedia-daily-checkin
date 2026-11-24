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
///
/// Labels ("Hari 4", "+3") always use the full text size the user chose: a
/// label may wrap ("Hari" over "4"), and when the words do not fit seven
/// slots side by side the week breaks into rows (4 + 3, or narrower).
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

  static const double _gap = 6;

  /// Column counts tried in order: one row of seven, then 4 + 3, and so on.
  static const List<int> _columnOptions = <int>[7, 4, 3, 2];

  @override
  Widget build(BuildContext context) {
    const int days = CheckInRules.bonusEvery;
    final int bloomed = filled.clamp(0, days);
    final int? todayIndex = claimedToday || bloomed == days ? null : bloomed;
    Widget slot(int index) => _DaySlot(
      day: index + 1,
      status: index < bloomed
          ? _SlotStatus.claimed
          : index == todayIndex
          ? _SlotStatus.today
          : _SlotStatus.upcoming,
      isBonusDay: index == days - 1,
      currencyIcon: currencyIcon,
      bonusIcon: bonusIcon,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int columns = _columnOptions.last;
        for (final int option in _columnOptions) {
          if (_fits(context, _cellWidth(width, option))) {
            columns = option;
            break;
          }
        }
        if (columns == days) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: _gap,
            children: <Widget>[
              for (int index = 0; index < days; index++)
                Expanded(child: slot(index)),
            ],
          );
        }
        final double cell = _cellWidth(width, columns);
        return Column(
          spacing: _gap * 2,
          children: <Widget>[
            for (int start = 0; start < days; start += columns)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _gap,
                children: <Widget>[
                  for (
                    int index = start;
                    index < math.min(start + columns, days);
                    index++
                  )
                    SizedBox(width: cell, child: slot(index)),
                ],
              ),
          ],
        );
      },
    );
  }

  static double _cellWidth(double width, int columns) =>
      (width - _gap * (columns - 1)) / columns;

  /// Whether every label fits a cell of [cellWidth] at the current text
  /// size without shrinking: the word "Hari", the day number and the "+3"
  /// pill inside its tile.
  static bool _fits(BuildContext context, double cellWidth) {
    final TextStyle? style = _DaySlot.labelStyleBase(
      Theme.of(context),
    )?.copyWith(fontWeight: FontWeight.w700);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextDirection direction = Directionality.of(context);
    double widthOf(String text) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double result = painter.width;
      painter.dispose();
      return result;
    }

    final double tileInner =
        math.min(cellWidth, _DaySlot.maxTileWidth) - 2 * _SlotTile.sidePadding;
    return widthOf('Hari') <= cellWidth &&
        widthOf('${CheckInRules.bonusEvery}') <= cellWidth &&
        widthOf('+${CheckInRules.bonusKelopak}') + 2 * _BonusPill.sidePadding <=
            tileInner;
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

  /// Widest a tile grows.
  static const double maxTileWidth = 64;

  /// Text style every day label starts from.
  static TextStyle? labelStyleBase(ThemeData theme) =>
      theme.textTheme.labelSmall;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? labelStyle = labelStyleBase(theme)?.copyWith(
      color: switch (status) {
        _SlotStatus.claimed => scheme.onSurface,
        _SlotStatus.today => scheme.secondary,
        _SlotStatus.upcoming => scheme.onSurfaceVariant,
      },
      fontWeight: status == _SlotStatus.today ? FontWeight.w700 : null,
    );
    final Widget tile = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxTileWidth),
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
          Text(
            'Hari $day',
            textAlign: TextAlign.center,
            softWrap: true,
            style: labelStyle,
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

  /// Inner padding left and right of the artwork.
  static const double sidePadding = 4;

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
              padding: const EdgeInsets.fromLTRB(
                sidePadding,
                8,
                sidePadding,
                4,
              ),
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

/// "+3" on the bonus day, at the user's full text size.
class _BonusPill extends StatelessWidget {
  const _BonusPill();

  /// Padding left and right of the label.
  static const double sidePadding = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.tertiary,
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: sidePadding,
            vertical: 1,
          ),
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
