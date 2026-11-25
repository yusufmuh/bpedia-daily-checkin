import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Satu langkah "Cara main".
@immutable
class _Step {
  const _Step(this.art, this.title, this.reward);

  final ImageProvider art;
  final String title;
  final String reward;
}

const List<_Step> _steps = <_Step>[
  _Step(CheckInArt.calendar, 'Check-in tiap hari', '+1 Kelopak'),
  _Step(CheckInArt.giftClosed, '7 hari beruntun', 'Bonus +3 Kelopak'),
  _Step(CheckInArt.giftOpen, '30 hari tanpa putus', '1 produk gratis'),
];

/// "Cara main": tiga langkah berikon 3D, kurs Kelopak, dan tautan S&K.
///
/// Tiga kolom pada huruf normal; daftar tegak pada huruf besar atau panel
/// sempit.
class CheckInHowTo extends StatelessWidget {
  /// Membuat blok cara main.
  const CheckInHowTo({super.key, this.onOpenTerms});

  /// Membuka syarat dan ketentuan lengkap. `null` menyembunyikan tautan.
  final VoidCallback? onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle titleStyle = base.copyWith(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: tones.text,
    );
    final TextStyle rewardStyle = base.copyWith(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w700,
      color: tones.onGoldTint,
    );

    Widget number(int index) => DecoratedBox(
      decoration: BoxDecoration(color: tones.brand, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 18,
        child: Center(
          child: Text(
            '${index + 1}',
            textScaler: TextScaler.noScaling,
            style: base.copyWith(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              color: tones.onBrand,
            ),
          ),
        ),
      ),
    );

    Widget art(int index) => SizedBox.square(
      dimension: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tones.brandTint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Bobbing(
              amplitude: 2.5,
              phase: index / 3,
              child: Image(
                image: _steps[index].art,
                width: 46,
                height: 46,
              ),
            ),
          ),
          Positioned(top: -2, left: -2, child: number(index)),
        ],
      ),
    );

    Widget reward(int index) => DecoratedBox(
      decoration: ShapeDecoration(
        color: tones.goldTint,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          _steps[index].reward,
          textAlign: TextAlign.center,
          style: rewardStyle,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool columns =
            MediaQuery.textScalerOf(context).scale(12) <= 15 &&
            constraints.maxWidth >= 280;
        final Widget steps = columns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < _steps.length; i++) ...<Widget>[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: tones.brandLine,
                        ),
                      ),
                    Expanded(
                      child: Semantics(
                        container: true,
                        label:
                            'Langkah ${i + 1}: ${_steps[i].title}, '
                            '${_steps[i].reward}',
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              art(i),
                              const SizedBox(height: 8),
                              Text(
                                _steps[i].title,
                                textAlign: TextAlign.center,
                                style: titleStyle,
                              ),
                              const SizedBox(height: 4),
                              reward(i),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < _steps.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      label:
                          'Langkah ${i + 1}: ${_steps[i].title}, '
                          '${_steps[i].reward}',
                      child: ExcludeSemantics(
                        child: Row(
                          children: <Widget>[
                            art(i),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(_steps[i].title, style: titleStyle),
                                  const SizedBox(height: 4),
                                  reward(i),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            steps,
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tones.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: <Widget>[
                    const Image(image: CheckInArt.coin, width: 22, height: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '1 Kelopak = Rp100. Otomatis memotong belanja saat '
                        'checkout.',
                        style: base.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          color: tones.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onOpenTerms != null)
              Center(
                child: Pressable(
                  onTap: onOpenTerms,
                  semanticLabel: 'Syarat dan ketentuan',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Text(
                      'Syarat dan ketentuan',
                      style: base.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w600,
                        color: tones.brand,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Aturan singkat Check-in Harian untuk lembar "Aturan".
const List<String> checkInRuleLines = <String>[
  'Satu check-in per hari WIB, tiap check-in dapat +1 Kelopak.',
  'Tiap hari ke-7 beruntun dapat bonus +3 Kelopak, jadi 7 hari = 10 Kelopak.',
  '30 hari tanpa putus dapat 1 produk gratis. Hadiah masuk ke keranjang dan '
      'dikirim bersama pesanan belanja berikutnya, tanpa ongkir tambahan.',
  'Terlewat satu hari, streak mulai lagi dari hari ke-1. Kelopak dan hadiah '
      'yang sudah didapat tidak hilang.',
  'Hari berganti pukul 00.00 WIB.',
  '1 Kelopak = Rp100 dan otomatis memotong belanja saat checkout.',
];

/// Menampilkan lembar "Aturan" dari bawah layar.
Future<void> showCheckInRulesSheet(
  BuildContext context, {
  VoidCallback? onOpenTerms,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: FestivePalette.panelColor(Theme.of(context).colorScheme),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext sheet) {
      final ThemeData theme = Theme.of(sheet);
      final CheckInTones tones = CheckInTones.of(sheet);
      final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Aturan Check-in Harian',
                    style: base.copyWith(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: tones.text,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < checkInRuleLines.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tones.brand,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(dimension: 8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            checkInRuleLines[i],
                            style: base.copyWith(
                              fontSize: 14,
                              height: 20 / 14,
                              color: tones.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                CandyButton(
                  label: 'Mengerti',
                  shine: false,
                  onPressed: () => Navigator.pop(sheet),
                ),
                if (onOpenTerms != null)
                  Center(
                    child: Pressable(
                      onTap: () {
                        Navigator.pop(sheet);
                        onOpenTerms();
                      },
                      semanticLabel: 'Baca syarat dan ketentuan lengkap',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Text(
                          'Baca syarat dan ketentuan lengkap',
                          textAlign: TextAlign.center,
                          style: base.copyWith(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w600,
                            color: tones.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
