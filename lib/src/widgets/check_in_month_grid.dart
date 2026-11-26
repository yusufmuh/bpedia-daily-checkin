import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_engine.dart';
import '../check_in_view.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Kisi 30 hari, tujuh kolom, mengikuti rancangan desainer owner.
///
/// Tiap sel berlabel "Hari N" (atau "Hari ini") di atas ikon dan nilai
/// Kelopaknya. Hari bonus (hari streak kelipatan 7) berkepala pink dengan
/// kado "+4", hari yang sudah diklaim memakai satu warna sukses dengan
/// centang hijau, dan kartu "Selesai 30 hari!" mengisi sisa baris terakhir.
/// Pada huruf besar kartu itu turun ke baris sendiri.
class CheckInMonthGrid extends StatelessWidget {
  /// Membuat kisi dengan [day] hari terisi (dibatasi 0..30).
  const CheckInMonthGrid({
    super.key,
    required this.day,
    required this.claimedToday,
    this.cycleStart = 0,
    this.rewardImage,
    this.todayAnchorKey,
    this.stampLatest = false,
  });

  /// Hari terisi di siklus 30 hari ini.
  final int day;

  /// Hari ini sudah diklaim (tidak ada sel "Hari ini").
  final bool claimedToday;

  /// Jumlah hari streak sebelum sel pertama. Menentukan sel mana yang jatuh
  /// di kelipatan 7 pada siklus kedua dan seterusnya.
  final int cycleStart;

  /// Foto produk hadiah di kartu "Selesai 30 hari!". `null` = tanpa foto.
  final ImageProvider? rewardImage;

  /// Dipasang pada ikon sel hari ini, atau sel terakhir yang diklaim bila
  /// hari ini sudah diklaim. Titik awal koin terbang.
  final GlobalKey? todayAnchorKey;

  /// Sel terakhir yang diklaim membal sekali (dipakai tepat setelah klaim).
  final bool stampLatest;

  static const int _columns = 7;
  static const double _gap = 6;

  /// Posisi sel yang jatuh di hari bonus untuk siklus yang dimulai setelah
  /// [cycleStart] hari streak.
  static List<int> bonusPositions(int cycleStart) => <int>[
    for (int p = 1; p <= CheckInRules.productEvery; p++)
      if ((cycleStart + p) % CheckInRules.bonusEvery == 0) p,
  ];

  @override
  Widget build(BuildContext context) {
    final CheckInTones tones = CheckInTones.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final int filled = day.clamp(0, CheckInRules.productEvery);
    final int? today = !claimedToday && filled < CheckInRules.productEvery
        ? filled + 1
        : null;
    final int? anchor = today ?? (filled > 0 ? filled : null);
    final List<int> bonusDays = bonusPositions(cycleStart);

    Widget cell(int position) => Expanded(
      child: _DayCell(
        position: position,
        claimed: position <= filled,
        today: position == today,
        bonus: bonusDays.contains(position),
        stamp: stampLatest && claimedToday && position == filled,
        anchorKey: position == anchor ? todayAnchorKey : null,
        tones: tones,
      ),
    );

    Widget row(List<Widget> children) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cellWidth =
            (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final List<Widget> rows = <Widget>[];
        // Huruf besar atau kisi sempit: lima kolom supaya label "Hari N"
        // tetap terbaca, kartu tujuan turun ke baris sendiri.
        final bool large = scaler.scale(12) > 16 || cellWidth < 36;
        if (large) {
          const int columns = 5;
          rows.addAll(<Widget>[
            for (int r = 0; r < CheckInRules.productEvery ~/ columns; r++)
              row(<Widget>[
                for (int col = 0; col < columns; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: _gap),
                  cell(r * columns + col + 1),
                ],
              ]),
            _GoalBanner(tones: tones, image: rewardImage, wide: true),
          ]);
        } else {
          rows.addAll(<Widget>[
            for (int r = 0; r < 4; r++)
              row(<Widget>[
                for (int col = 0; col < _columns; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: _gap),
                  cell(r * _columns + col + 1),
                ],
              ]),
            row(<Widget>[
              cell(29),
              const SizedBox(width: _gap),
              cell(30),
              const SizedBox(width: _gap),
              // Lima kolom ditambah empat celah di antaranya.
              SizedBox(
                width: cellWidth * 5 + _gap * 4,
                child: _GoalBanner(
                  tones: tones,
                  image: rewardImage,
                  wide: false,
                ),
              ),
            ]),
          ]);
        }
        return Semantics(
          container: true,
          label: 'Kalender 30 hari',
          value: _summary(filled, today, bonusDays),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: _gap),
                  rows[i],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _summary(int filled, int? today, List<int> bonusDays) {
    final String bonus = bonusDays.map((int d) => 'ke-$d').join(', ');
    final String now = today == null ? '' : ' Hari ini hari ke-$today.';
    return '$filled dari 30 hari sudah check-in.$now '
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
    required this.stamp,
    required this.anchorKey,
    required this.tones,
  });

  final int position;
  final bool claimed;
  final bool today;
  final bool bonus;
  final bool stamp;
  final GlobalKey? anchorKey;
  final CheckInTones tones;

  static const Radius _radius = Radius.circular(10);

  Color get _fill {
    if (claimed) return tones.successTint;
    if (today && !bonus) return tones.surface;
    if (bonus) return tones.goldTint;
    return tones.muted;
  }

  Border get _border {
    if (today) return Border.all(color: tones.brand, width: 2);
    if (bonus) return Border.all(color: tones.gold, width: 1.5);
    return Border.all(color: claimed ? tones.successTint : tones.line);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final TextScaler scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.6);
    final String label = today ? 'Hari ini' : 'Hari $position';
    final int kelopak =
        CheckInRules.dailyKelopak + (bonus ? CheckInRules.bonusKelopak : 0);

    Widget fitted(String text, TextStyle style) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textScaler: scaler,
        style: style,
      ),
    );

    final Widget head = bonus
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: FestivePalette.candy,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(today ? 8 : 8.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Center(
                child: fitted(
                  label,
                  base.copyWith(
                    fontSize: 10,
                    height: 12 / 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: Center(
              child: fitted(
                label,
                base.copyWith(
                  fontSize: 10,
                  height: 12 / 10,
                  fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0,
                  color: today ? tones.brand : tones.textMuted,
                ),
              ),
            ),
          );

    final Widget icon;
    if (claimed) {
      icon = DecoratedBox(
        decoration: BoxDecoration(color: tones.success, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: 22,
          child: Icon(Icons.check_rounded, size: 17, color: tones.onSuccess),
        ),
      );
    } else if (bonus) {
      icon = const Image(image: CheckInArt.giftClosed, width: 22, height: 22);
    } else {
      const Widget coin = Image(image: CheckInArt.coin, width: 22, height: 22);
      icon = today
          ? coin
          : Opacity(
              opacity: 0.8,
              child: ColorFiltered(
                colorFilter: saturationFilter(0.55),
                child: coin,
              ),
            );
    }

    Widget body = Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: const BorderRadius.all(_radius),
        border: _border,
        boxShadow: today
            ? <BoxShadow>[
                BoxShadow(
                  color: tones.brand.withValues(alpha: 0.22),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          head,
          const SizedBox(height: 1),
          Center(
            child: SizedBox(
              key: anchorKey,
              height: 22,
              child: Center(child: icon),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 1, 2, 3),
            child: Center(
              child: fitted(
                '+$kelopak',
                base.copyWith(
                  fontSize: 11,
                  height: 13 / 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: claimed
                      ? tones.success
                      : bonus
                      ? tones.onGoldTint
                      : tones.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (stamp && !reduceMotionOf(context)) {
      body = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.25, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
        builder: (BuildContext context, double scale, Widget? child) =>
            Transform.scale(scale: scale, child: child),
        child: body,
      );
    }
    return body;
  }
}

class _GoalBanner extends StatelessWidget {
  const _GoalBanner({
    required this.tones,
    required this.image,
    required this.wide,
  });

  final CheckInTones tones;
  final ImageProvider? image;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final ImageProvider? image = this.image;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tones.dark
              ? const <Color>[Color(0xFF3F1A2A), Color(0xFF3A2C0A)]
              : const <Color>[Color(0xFFFFEDF2), Color(0xFFFFF4DB)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tones.gold, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, wide ? 8 : 4, 8, wide ? 8 : 4),
        child: Row(
          children: <Widget>[
            const Bobbing(
              amplitude: 2,
              tilt: 0.05,
              child: Image(image: CheckInArt.giftClosed, width: 40, height: 40),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Selesai 30 hari!',
                    maxLines: wide ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 13,
                      height: 17 / 13,
                      fontWeight: FontWeight.w800,
                      color: tones.brand,
                    ),
                  ),
                  Text(
                    'Dapat 1 produk gratis',
                    maxLines: wide ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 11,
                      height: 15 / 11,
                      fontWeight: FontWeight.w600,
                      color: tones.text,
                    ),
                  ),
                ],
              ),
            ),
            if (image != null) ...<Widget>[
              const SizedBox(width: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image(
                  image: image,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu baris di atas kisi: "Hari ke-N dari 30", nama hadiah, dan fotonya.
///
/// Dengan [onOpenProduct] baris menjadi tombol ke detail produk.
class CheckInCycleHeader extends StatelessWidget {
  /// Membuat baris progres untuk hari [day] di siklus 30 hari.
  const CheckInCycleHeader({
    super.key,
    required this.day,
    this.product,
    this.onOpenProduct,
  });

  /// Hari yang sedang berjalan di siklus (1..30). Nilai di luar dibatasi.
  final int day;

  /// Produk hadiah hari ke-30. `null` = hadiah umum.
  final CheckInRewardProduct? product;

  /// Membuka detail [product].
  final VoidCallback? onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final CheckInTones tones = CheckInTones.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final int current = day.clamp(1, CheckInRules.productEvery);
    final CheckInRewardProduct? product = this.product;
    final String prize = product?.name ?? '1 produk gratis pilihan Bpedia';
    final Widget content = Row(
      children: <Widget>[
        Image(
          image: CheckInArt.tulips[CheckInArt.tulipStage(current - 1)],
          width: 30,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Hari ke-$current',
                      style: TextStyle(color: tones.brand),
                    ),
                    const TextSpan(text: ' dari ${CheckInRules.productEvery}'),
                  ],
                ),
                style: base.copyWith(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w800,
                  color: tones.text,
                ),
              ),
              Text(
                'Hadiah: $prize',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  color: tones.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product == null
              ? DecoratedBox(
                  decoration: BoxDecoration(color: tones.goldTint),
                  child: const SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: Image(
                        image: CheckInArt.giftClosed,
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),
                )
              : Image(
                  image: product.image,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
        ),
      ],
    );
    final String semantics =
        'Hari ke-$current dari ${CheckInRules.productEvery}. Hadiah: $prize';
    if (onOpenProduct == null) {
      return Semantics(
        container: true,
        label: semantics,
        child: ExcludeSemantics(child: content),
      );
    }
    return Pressable(
      onTap: onOpenProduct,
      semanticLabel: '$semantics. Lihat produk',
      pressedScale: 0.98,
      child: content,
    );
  }
}
