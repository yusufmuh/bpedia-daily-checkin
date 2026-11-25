import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_engine.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Kisi 30 hari, tujuh kolom, mengikuti rancangan desainer owner.
///
/// Hari bonus (hari streak kelipatan 7) berlatar emas dengan lencana "+3",
/// hari ke-30 berkado, dan spanduk "30 hari = 1 produk gratis" mengisi sisa
/// baris terakhir. Pada huruf besar spanduk turun ke baris sendiri.
class CheckInMonthGrid extends StatelessWidget {
  /// Membuat kisi dengan [day] hari terisi (dibatasi 0..30).
  const CheckInMonthGrid({
    super.key,
    required this.day,
    required this.claimedToday,
    this.cycleStart = 0,
  });

  /// Hari terisi di siklus 30 hari ini.
  final int day;

  /// Hari ini sudah diklaim (tidak ada sel "hari ini").
  final bool claimedToday;

  /// Jumlah hari streak sebelum sel pertama. Menentukan sel mana yang jatuh
  /// di kelipatan 7 pada siklus kedua dan seterusnya.
  final int cycleStart;

  static const int _columns = 7;

  @override
  Widget build(BuildContext context) {
    final CheckInTones tones = CheckInTones.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final int filled = day.clamp(0, CheckInRules.productEvery);
    final int? today = !claimedToday && filled < CheckInRules.productEvery
        ? filled + 1
        : null;
    final List<int> bonusDays = <int>[
      for (int p = 1; p <= CheckInRules.productEvery; p++)
        if ((cycleStart + p) % CheckInRules.bonusEvery == 0) p,
    ];

    Widget cell(int position) => Expanded(
      child: _DayCell(
        position: position,
        claimed: position <= filled,
        today: position == today,
        bonus: bonusDays.contains(position),
        tones: tones,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 4;
        final double cellWidth =
            (constraints.maxWidth - gap * (_columns - 1)) / _columns;
        final bool stackBanner = scaler.scale(10) > 12.5 || cellWidth < 36;
        final List<Widget> rows = <Widget>[
          for (int row = 0; row < 4; row++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int col = 0; col < _columns; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: gap),
                  cell(row * _columns + col + 1),
                ],
              ],
            ),
          if (stackBanner) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                cell(29),
                const SizedBox(width: gap),
                cell(30),
                const SizedBox(width: gap),
                const Spacer(flex: 5),
              ],
            ),
            _GoalBanner(tones: tones, wide: true),
          ] else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  cell(29),
                  const SizedBox(width: gap),
                  cell(30),
                  const SizedBox(width: gap),
                  // Lima kolom ditambah empat celah di antaranya.
                  SizedBox(
                    width: cellWidth * 5 + gap * 4,
                    child: _GoalBanner(tones: tones, wide: false),
                  ),
                ],
              ),
            ),
        ];
        return Semantics(
          container: true,
          label: 'Kalender 30 hari',
          value: _summary(filled, bonusDays),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 7),
                  rows[i],
                ],
                const SizedBox(height: 12),
                _Legend(tones: tones),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _summary(int filled, List<int> bonusDays) {
    final String bonus = bonusDays.map((int d) => 'ke-$d').join(', ');
    return '$filled dari 30 hari sudah check-in. '
        'Bonus 3 Kelopak di hari $bonus. '
        'Hari ke-30 dapat 1 produk gratis.';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.position,
    required this.claimed,
    required this.today,
    required this.bonus,
    required this.tones,
  });

  final int position;
  final bool claimed;
  final bool today;
  final bool bonus;
  final CheckInTones tones;

  bool get _gift => position == CheckInRules.productEvery;

  BoxDecoration get _decoration {
    final BorderRadius radius = BorderRadius.circular(10);
    if (_gift) {
      return BoxDecoration(
        gradient: FestivePalette.candy,
        borderRadius: radius,
        border: Border.all(
          color: today ? Colors.white : FestivePalette.candyLip,
          width: today ? 2 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33D81F57), blurRadius: 8, offset: Offset(0, 3)),
        ],
      );
    }
    if (today) {
      return BoxDecoration(
        color: bonus ? tones.goldTint : tones.surface,
        borderRadius: radius,
        border: Border.all(color: tones.brand, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(color: tones.brand.withValues(alpha: 0.25), blurRadius: 8),
        ],
      );
    }
    if (bonus) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tones.dark
              ? const <Color>[Color(0xFF5A4209), Color(0xFF3A2C0A)]
              : const <Color>[Color(0xFFFFF1C2), Color(0xFFFFDC7A)],
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
    final TextStyle base =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final Color numberColor = _gift
        ? Colors.white
        : today
        ? tones.brand
        : (claimed || bonus)
        ? tones.onGoldTint
        : tones.textMuted;
    Widget art = Image(
      image: _gift
          ? (claimed ? CheckInArt.giftOpen : CheckInArt.giftClosed)
          : CheckInArt.coin,
      width: _gift ? 28 : 22,
      height: _gift ? 28 : 22,
    );
    if (!claimed && !today && !_gift && !bonus) {
      art = Opacity(
        opacity: 0.75,
        child: ColorFiltered(colorFilter: saturationFilter(0.4), child: art),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        DecoratedBox(
          decoration: _decoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 4, 1, 5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$position',
                    maxLines: 1,
                    softWrap: false,
                    style: base.copyWith(
                      fontSize: 10,
                      height: 14 / 10,
                      fontWeight: today || _gift
                          ? FontWeight.w800
                          : FontWeight.w600,
                      letterSpacing: 0,
                      color: numberColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: <Widget>[
                        art,
                        if (claimed)
                          Positioned(
                            right: -5,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: tones.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tones.dark
                                      ? tones.goldTint
                                      : Colors.white,
                                ),
                              ),
                              child: SizedBox.square(
                                dimension: 13,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 10,
                                  color: tones.onSuccess,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (bonus && !_gift)
          Positioned(
            top: -6,
            right: -3,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: tones.brand,
                shape: StadiumBorder(
                  side: BorderSide(color: tones.surface, width: 1.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                child: Text(
                  '+${CheckInRules.bonusKelopak}',
                  maxLines: 1,
                  softWrap: false,
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.4),
                  style: base.copyWith(
                    fontSize: 9,
                    height: 12 / 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: tones.onBrand,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoalBanner extends StatelessWidget {
  const _GoalBanner({required this.tones, required this.wide});

  final CheckInTones tones;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tones.dark
              ? const <Color>[Color(0xFF3A2C0A), Color(0xFF4A3608)]
              : const <Color>[Color(0xFFFFF4DB), Color(0xFFFFE7A8)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tones.goldLine),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, wide ? 8 : 4, 10, wide ? 8 : 4),
        child: Row(
          children: <Widget>[
            const Bobbing(
              amplitude: 2,
              tilt: 0.05,
              child: Image(
                image: CheckInArt.giftClosed,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '30 hari = 1 produk gratis',
                    maxLines: wide ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 12,
                      height: 15 / 12,
                      fontWeight: FontWeight.w800,
                      color: tones.onGoldTint,
                    ),
                  ),
                  Text(
                    'Check-in tanpa putus',
                    maxLines: wide ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 10,
                      height: 14 / 10,
                      fontWeight: FontWeight.w500,
                      color: tones.onGoldTint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.tones});

  final CheckInTones tones;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: 11,
          height: 14 / 11,
          color: tones.textMuted,
        );
    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: style)),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        item(
          const Image(image: CheckInArt.coin, width: 16, height: 16),
          '+1 Kelopak',
        ),
        item(
          DecoratedBox(
            decoration: BoxDecoration(
              color: tones.dark
                  ? const Color(0xFF5A4209)
                  : const Color(0xFFFFDC7A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tones.gold),
            ),
            child: const SizedBox.square(dimension: 14),
          ),
          'Bonus +3 Kelopak',
        ),
        item(
          const Image(image: CheckInArt.giftClosed, width: 18, height: 18),
          'Produk gratis',
        ),
      ],
    );
  }
}
