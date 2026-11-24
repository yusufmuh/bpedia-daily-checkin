import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'check_in_engine.dart';

/// Progress towards the free product of day 30.
///
/// Shows "Menuju produk gratis", "{day} dari 30 hari", a pill track with
/// dots on the bonus days 7, 14, 21 and 28, and the reward at the end
/// ([rewardImage] at 28 dp, fallback [Icons.redeem]). Screen readers get one
/// node: label "Progres produk gratis", value "{day} dari 30 hari".
///
/// Use [dayInMonthCycle] for [day].
class CheckInMonthProgress extends StatelessWidget {
  /// Creates the 30-day progress.
  const CheckInMonthProgress({super.key, required this.day, this.rewardImage});

  /// Days completed in the current cycle, 0..30 (values outside are clamped).
  final int day;

  /// Artwork of the free product; [Icons.redeem] when null.
  final Widget? rewardImage;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    const int goal = CheckInRules.productEvery;
    final int current = day.clamp(0, goal);
    final bool reached = current == goal;
    final String progress = '$current dari $goal hari';
    return Semantics(
      container: true,
      label: 'Progres produk gratis',
      value: progress,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 2,
            children: <Widget>[
              Text(
                'Menuju produk gratis',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              Text(
                progress,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: reached ? scheme.secondary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            spacing: 8,
            children: <Widget>[
              Expanded(
                child: CustomPaint(
                  size: const Size.fromHeight(16),
                  painter: _MonthTrackPainter(
                    day: current,
                    track: scheme.secondaryContainer,
                    fill: scheme.primary,
                    passedDot: scheme.onPrimary,
                    pendingDot: scheme.outline,
                  ),
                ),
              ),
              _RewardSlot(reached: reached, image: rewardImage),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardSlot extends StatelessWidget {
  const _RewardSlot({required this.reached, required this.image});

  final bool reached;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? scheme.tertiaryContainer : null,
        ),
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(
              size: 28,
              color: reached ? scheme.onTertiaryContainer : scheme.primary,
            ),
            child: SizedBox.square(
              dimension: 28,
              child: image ?? const Icon(Icons.redeem),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthTrackPainter extends CustomPainter {
  const _MonthTrackPainter({
    required this.day,
    required this.track,
    required this.fill,
    required this.passedDot,
    required this.pendingDot,
  });

  static const double _trackHeight = 10;
  static const double _dotRadius = 2.5;

  final int day;
  final Color track;
  final Color fill;
  final Color passedDot;
  final Color pendingDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    const int goal = CheckInRules.productEvery;
    final double top = (size.height - _trackHeight) / 2;
    final Rect bar = Rect.fromLTWH(0, top, size.width, _trackHeight);
    const Radius pill = Radius.circular(_trackHeight / 2);
    final RRect trackShape = RRect.fromRectAndRadius(bar, pill);
    canvas.drawRRect(trackShape, Paint()..color = track);
    if (day > 0) {
      final double end = size.width * day / goal;
      final double width = math.min(
        math.max(end + _trackHeight / 2, _trackHeight),
        size.width,
      );
      canvas
        ..save()
        ..clipRRect(trackShape)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, width, _trackHeight),
            pill,
          ),
          Paint()..color = fill,
        )
        ..restore();
    }
    final Paint passed = Paint()..color = passedDot;
    final Paint pending = Paint()
      ..color = pendingDot
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (
      int milestone = CheckInRules.bonusEvery;
      milestone < goal;
      milestone += CheckInRules.bonusEvery
    ) {
      final Offset center = Offset(
        size.width * milestone / goal,
        top + _trackHeight / 2,
      );
      canvas.drawCircle(
        center,
        _dotRadius,
        day >= milestone ? passed : pending,
      );
    }
  }

  @override
  bool shouldRepaint(_MonthTrackPainter oldDelegate) =>
      oldDelegate.day != day ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill ||
      oldDelegate.passedDot != passedDot ||
      oldDelegate.pendingDot != pendingDot;
}
