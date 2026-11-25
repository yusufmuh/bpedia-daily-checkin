import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_engine.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Kepala panel "Menuju produk gratis": pot tulip yang tumbuh lima tahap,
/// "N dari 30 hari", dan bar progres bertonggak 7/14/21/30.
class CheckInMonthProgress extends StatelessWidget {
  /// Membuat progres dengan [day] hari terisi (dibatasi 0..30).
  const CheckInMonthProgress({super.key, required this.day});

  /// Hari terisi di siklus 30 hari ini.
  final int day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final int filled = day.clamp(0, CheckInRules.productEvery);
    final int left = CheckInRules.productEvery - filled;
    final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
    final String title = filled == 0
        ? 'Mulai dari hari ke-1'
        : '$filled dari 30 hari';
    final String subtitle = left == 0
        ? 'Tuntas! Produk gratismu masuk ke keranjang.'
        : '$left hari lagi menuju produk gratis';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        TulipPot(stage: CheckInArt.tulipStage(filled)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: base.copyWith(
                  fontSize: 18,
                  height: 24 / 18,
                  fontWeight: FontWeight.w800,
                  color: tones.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: base.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  color: tones.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label: 'Progres produk gratis',
                value: '$filled dari 30 hari',
                child: ExcludeSemantics(
                  child: _MilestoneBar(day: filled, tones: tones),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pot tulip 3D yang berganti tahap dengan pegas dan bergoyang pelan.
class TulipPot extends StatelessWidget {
  /// Membuat pot pada [stage] 0..4 (tunas sampai mekar penuh).
  const TulipPot({super.key, required this.stage, this.height = 104});

  /// Tahap tumbuh 0..4.
  final int stage;

  /// Tinggi seni (dp).
  final double height;

  @override
  Widget build(BuildContext context) {
    final CheckInTones tones = CheckInTones.of(context);
    final int index = stage.clamp(0, CheckInArt.tulips.length - 1);
    final bool reduce = reduceMotionOf(context);
    final double width = height * 277 / 511;
    return Semantics(
      image: true,
      label: 'Tulip tahap ${index + 1} dari 5',
      child: SizedBox(
        width: width + 20,
        height: height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: height * 0.62,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[tones.brandTint, tones.goldTint],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Bobbing(
                amplitude: 1.5,
                tilt: 0.025,
                period: const Duration(milliseconds: 3400),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: reduce ? 200 : 520),
                  switchInCurve: reduce ? Curves.easeOut : Curves.elasticOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) => reduce
                      ? FadeTransition(opacity: animation, child: child)
                      : ScaleTransition(
                          scale: animation,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                  child: Image(
                    key: ValueKey<int>(index),
                    image: CheckInArt.tulips[index],
                    height: height - 8,
                    width: width,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.day, required this.tones});

  final int day;
  final CheckInTones tones;

  static const List<int> _marks = <int>[7, 14, 21, 30];

  @override
  Widget build(BuildContext context) {
    final TextStyle label =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontSize: 10,
          height: 14 / 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Tonggak terakhir berupa kado 26 dp; lintasan berakhir di tengahnya.
        const double end = 13;
        final double track = constraints.maxWidth - end;
        double x(int mark) => track * mark / CheckInRules.productEvery;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    width: track,
                    top: 9,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tones.muted,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: tones.line),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 9,
                    height: 10,
                    child: AnimatedContainer(
                      duration: reduceMotionOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: x(day),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[
                            FestivePalette.candyTop,
                            FestivePalette.gold,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  for (final int mark in _marks.take(3))
                    Positioned(
                      left: x(mark) - 7,
                      top: 7,
                      child: _Dot(reached: day >= mark, tones: tones),
                    ),
                  Positioned(
                    left: track - 13,
                    top: 1,
                    child: Image(
                      image: day >= CheckInRules.productEvery
                          ? CheckInArt.giftOpen
                          : CheckInArt.giftClosed,
                      width: 26,
                      height: 26,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(14),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (final int mark in _marks)
                    Positioned(
                      left: x(mark) - 24,
                      width: 48,
                      top: 0,
                      child: Text(
                        '$mark',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: label.copyWith(
                          color: day >= mark
                              ? tones.onGoldTint
                              : tones.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.reached, required this.tones});

  final bool reached;
  final CheckInTones tones;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? tones.gold : tones.surface,
        border: Border.all(
          color: reached ? Colors.white : tones.line,
          width: reached ? 2 : 1.5,
        ),
        boxShadow: reached
            ? const <BoxShadow>[
                BoxShadow(color: Color(0x33C98A0A), blurRadius: 4),
              ]
            : null,
      ),
      child: const SizedBox.square(dimension: 14),
    );
  }
}
