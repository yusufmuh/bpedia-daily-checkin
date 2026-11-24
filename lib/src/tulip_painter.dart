part of 'check_in_week_track.dart';

enum _TulipStage { bud, bloom }

@immutable
final class _TulipPalette {
  const _TulipPalette({
    required this.back,
    required this.front,
    required this.side,
    required this.stem,
  });

  /// Open flower: deep berry back petal, pink front petal, light side petal.
  factory _TulipPalette.vivid(ColorScheme scheme) => _TulipPalette(
    back: scheme.secondary,
    front: scheme.primary,
    side: _mix(scheme.primary, scheme.surfaceContainerLowest, 0.38),
    stem: scheme.onSurfaceVariant.withValues(alpha: 0.62),
  );

  /// Bud of a day that has not come yet.
  factory _TulipPalette.faded(ColorScheme scheme) => _TulipPalette(
    back: scheme.primary.withValues(alpha: 0.24),
    front: scheme.primary.withValues(alpha: 0.34),
    side: scheme.primary.withValues(alpha: 0.18),
    stem: scheme.onSurfaceVariant.withValues(alpha: 0.3),
  );

  final Color back;
  final Color front;
  final Color side;
  final Color stem;

  @override
  bool operator ==(Object other) =>
      other is _TulipPalette &&
      other.back == back &&
      other.front == front &&
      other.side == side &&
      other.stem == stem;

  @override
  int get hashCode => Object.hash(back, front, side, stem);
}

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

/// Draws the brand tulip (three petals) on a stem with one leaf.
///
/// Geometry is laid out in a unit square that is scaled to the shortest side
/// of the canvas and centred, so the drawing never distorts.
class _TulipPainter extends CustomPainter {
  const _TulipPainter({required this.stage, required this.palette});

  final _TulipStage stage;
  final _TulipPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    if (side <= 0) return;
    canvas
      ..save()
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(side);
    _paintStem(canvas);
    switch (stage) {
      case _TulipStage.bud:
        _paintBud(canvas);
      case _TulipStage.bloom:
        _paintBloom(canvas);
    }
    canvas.restore();
  }

  void _paintStem(Canvas canvas) {
    final double top = stage == _TulipStage.bloom ? 0.62 : 0.66;
    final Path stem = Path()
      ..moveTo(0.5, 0.97)
      ..quadraticBezierTo(0.46, 0.8, 0.5, top);
    canvas
      ..drawPath(
        stem,
        Paint()
          ..color = palette.stem
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        _petal(
          base: const Offset(0.49, 0.9),
          tip: const Offset(0.77, 0.7),
          left: 0.1,
          right: 0.08,
          baseLift: 0.25,
        ),
        Paint()..color = palette.stem,
      );
  }

  void _paintBud(Canvas canvas) {
    canvas
      ..drawPath(
        _petal(
          base: const Offset(0.5, 0.74),
          tip: const Offset(0.5, 0.2),
          left: 0.22,
          right: 0.22,
          baseLift: 0,
        ),
        Paint()..color = palette.front,
      )
      ..drawPath(
        _petal(
          base: const Offset(0.5, 0.74),
          tip: const Offset(0.41, 0.25),
          left: 0.2,
          right: 0.05,
          baseLift: 0,
        ),
        Paint()..color = palette.back,
      );
  }

  void _paintBloom(Canvas canvas) {
    canvas
      ..drawPath(
        _petal(
          base: const Offset(0.47, 0.68),
          tip: const Offset(0.13, 0.16),
          left: 0.2,
          right: 0.09,
          baseLift: 0.12,
        ),
        Paint()..color = palette.back,
      )
      ..drawPath(
        _petal(
          base: const Offset(0.53, 0.68),
          tip: const Offset(0.87, 0.16),
          left: 0.09,
          right: 0.2,
          baseLift: 0.12,
        ),
        Paint()..color = palette.side,
      )
      ..drawPath(
        _petal(
          base: const Offset(0.5, 0.72),
          tip: const Offset(0.5, 0.06),
          left: 0.2,
          right: 0.2,
          baseLift: 0.05,
        ),
        Paint()..color = palette.front,
      );
  }

  /// A pointed petal from [base] to [tip].
  ///
  /// [left] and [right] set how far each edge bulges, seen from the base
  /// towards the tip. [baseLift] near 0 gives a round base, larger values a
  /// narrower one.
  static Path _petal({
    required Offset base,
    required Offset tip,
    required double left,
    required double right,
    required double baseLift,
  }) {
    final Offset axis = tip - base;
    final Offset dir = axis / axis.distance;
    final Offset normal = Offset(-dir.dy, dir.dx);
    final Offset near = base + axis * baseLift;
    final Offset far = base + axis * 0.78;
    final Offset leftNear = near - normal * left;
    final Offset leftFar = far - normal * (left * 0.72);
    final Offset rightFar = far + normal * (right * 0.72);
    final Offset rightNear = near + normal * right;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        leftNear.dx,
        leftNear.dy,
        leftFar.dx,
        leftFar.dy,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        rightFar.dx,
        rightFar.dy,
        rightNear.dx,
        rightNear.dy,
        base.dx,
        base.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_TulipPainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.palette != palette;
}
