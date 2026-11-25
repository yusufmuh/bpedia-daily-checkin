import 'package:flutter/material.dart';

import '../check_in_assets.dart';
import '../check_in_format.dart';
import '../check_in_view.dart';
import '../kit/kit.dart';
import 'check_in_tones.dart';

/// Kartu hadiah hari ke-30: foto dan nama produk, harga dicoret dengan pil
/// "Gratis", dan catatan pengiriman bersama pesanan belanja.
///
/// Tanpa [product] kartu menampilkan kado umum dan tidak bisa diketuk.
class CheckInRewardCard extends StatelessWidget {
  /// Membuat kartu hadiah.
  const CheckInRewardCard({super.key, this.product, this.onOpen});

  /// Produk hadiah dari host.
  final CheckInRewardProduct? product;

  /// Dipanggil saat kartu diketuk (membuka detail produk).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CheckInTones tones = CheckInTones.of(context);
    final CheckInRewardProduct? product = this.product;
    final TextStyle base = theme.textTheme.bodyMedium ?? const TextStyle();
    final bool tappable = product != null && onOpen != null;

    final Widget picture = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: 68,
        child: product == null
            ? ColoredBox(
                color: tones.goldTint,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Image(image: CheckInArt.giftClosed),
                ),
              )
            : ColoredBox(
                color: tones.muted,
                child: Image(
                  image: product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object _, StackTrace? _) =>
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Image(image: CheckInArt.giftClosed),
                      ),
                ),
              ),
      ),
    );

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tones.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            picture,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Hadiah hari ke-30',
                    style: base.copyWith(
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      color: tones.onGoldTint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product?.name ?? '1 produk gratis pilihan Bpedia',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: base.copyWith(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      color: tones.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          color: tones.successTint,
                          shape: const StadiumBorder(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            'Gratis',
                            style: base.copyWith(
                              fontSize: 11,
                              height: 14 / 11,
                              fontWeight: FontWeight.w700,
                              color: tones.success,
                            ),
                          ),
                        ),
                      ),
                      if (product != null)
                        Text(
                          formatRupiah(product.price),
                          style: base.copyWith(
                            fontSize: 12,
                            height: 16 / 12,
                            color: tones.textMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: tones.textMuted,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.local_shipping_outlined,
                          size: 14,
                          color: tones.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Dikirim bersama pesanan belanjamu',
                          style: base.copyWith(
                            fontSize: 11,
                            height: 15 / 11,
                            color: tones.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (tappable)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: tones.textMuted,
                ),
              ),
          ],
        ),
      ),
    );

    if (!tappable) {
      return Semantics(
        container: true,
        label: product == null
            ? 'Hadiah hari ke-30: 1 produk gratis, dikirim bersama pesanan '
                  'belanjamu'
            : 'Hadiah hari ke-30: ${product.name}, gratis, dikirim bersama '
                  'pesanan belanjamu',
        child: ExcludeSemantics(child: card),
      );
    }
    return Pressable(
      onTap: onOpen,
      semanticLabel:
          'Hadiah hari ke-30: ${product.name}, gratis, dikirim bersama '
          'pesanan belanjamu. Lihat produk',
      focusRadius: const BorderRadius.all(Radius.circular(14)),
      child: card,
    );
  }
}
