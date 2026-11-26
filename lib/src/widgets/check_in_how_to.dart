import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Satu kolom kartu aturan.
@immutable
class _Rule {
  const _Rule(this.art, this.value, this.detail);

  final ImageProvider art;
  final String value;
  final String detail;
}

final List<_Rule> _rules = <_Rule>[
  const _Rule(CheckInArt.coin, '+1/hari', 'Kelopak tiap check-in'),
  const _Rule(CheckInArt.giftClosed, '7 hari', 'Bonus +3 Kelopak'),
  _Rule(CheckInArt.tulips.last, '30 hari', '1 produk gratis'),
];

/// Kartu tiga aturan di bawah hero: +1/hari, 7 hari bonus +3, 30 hari
/// produk gratis. Tiga kolom berikon pada huruf normal; daftar tegak pada
/// huruf besar atau kartu sempit.
class CheckInHowTo extends StatelessWidget {
  /// Membuat kartu aturan.
  const CheckInHowTo({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle valueStyle = base.copyWith(
      fontSize: 14,
      height: 18 / 14,
      fontWeight: FontWeight.w800,
      color: tones.brand,
    );
    final TextStyle detailStyle = base.copyWith(
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      color: tones.text,
    );

    Widget rule(int i) => Semantics(
      container: true,
      label: '${_rules[i].value}: ${_rules[i].detail}',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Bobbing(
              amplitude: 1.5,
              phase: i / 3,
              child: Image(image: _rules[i].art, width: 26, height: 26),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_rules[i].value, style: valueStyle),
                  Text(_rules[i].detail, style: detailStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool columns =
            MediaQuery.textScalerOf(context).scale(12) <= 15 &&
            constraints.maxWidth >= 300;
        if (!columns) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < _rules.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 10),
                rule(i),
              ],
            ],
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < _rules.length; i++) ...<Widget>[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: tones.line,
                      ),
                    ),
                  Expanded(child: rule(i)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Butir "Ketentuan" di bawah kisi 30 hari.
const List<String> checkInTermLines = <String>[
  'Hari dihitung WIB, klaim dibuka pukul 00.00.',
  'Terlewat satu hari, streak dan kisi 30 hari mulai lagi dari hari 1. '
      'Kelopak dan hadiah yang sudah didapat tidak hilang.',
  'Kelopak masuk saldo dan memotong harga barang saat checkout '
      '(1 Kelopak = Rp100).',
];

/// Panel "Ketentuan": butir aturan singkat dan tautan syarat lengkap.
class CheckInTerms extends StatelessWidget {
  /// Membuat isi panel ketentuan.
  const CheckInTerms({super.key, this.onOpenTerms});

  /// Membuka syarat dan ketentuan lengkap. `null` menyembunyikan tautan.
  final VoidCallback? onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final CheckInTones tones = CheckInTones.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final String line in checkInTermLines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tones.textMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: base.copyWith(
                      fontSize: 13,
                      height: 19 / 13,
                      color: tones.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (onOpenTerms != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Pressable(
              onTap: onOpenTerms,
              semanticLabel: 'Syarat dan ketentuan',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Syarat dan ketentuan lengkap',
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
