import 'package:flutter/material.dart';

/// Calendar day in Asia/Jakarta. Indonesia's western zone is UTC+07 year-round.
int wibDay(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 7)).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

typedef CheckInAward = ({int streak, int kelopak, bool product});

CheckInAward? evaluateCheckIn({required int today, required int? last, required int streak}) {
  if (last != null && today <= last) return null;
  final next = last == today - 1 ? streak + 1 : 1;
  return (streak: next, kelopak: 1 + (next % 7 == 0 ? 3 : 0), product: next % 30 == 0);
}

class DailyCheckInView extends StatelessWidget {
  const DailyCheckInView({super.key, required this.streak, required this.claimed,
    required this.products, required this.onClaim});
  final int streak;
  final bool claimed;
  final int products;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final marked = streak == 0 ? 0 : (streak - 1) % 7 + 1;
    final monthly = streak == 0 ? 0 : (streak - 1) % 30 + 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Jejak tujuh hari', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Ambil 1 Kelopak per hari. Lengkapi tujuh hari beruntun untuk tambahan 3 Kelopak.'),
      const SizedBox(height: 16),
      Wrap(spacing: 7, runSpacing: 8, children: List.generate(7, (i) => Semantics(
        label: 'Hari ${i+1}, ${i < marked ? "tercapai" : "belum tercapai"}',
        child: ExcludeSemantics(child: Container(width: 53, padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: i < marked ? const Color(0xfff6cfda) : const Color(0xfff9f0ef),
            borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Icon(i < marked ? Icons.check_circle : (i == 6 ? Icons.card_giftcard : Icons.spa_outlined),
            color: const Color(0xff982149), size: 22), Text('Hari ${i+1}', style: const TextStyle(fontSize: 12))])))))),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: claimed ? null : onClaim, icon: Icon(claimed ? Icons.check : Icons.spa),
        label: Text(claimed ? 'Sudah check-in hari ini' : 'Ambil 1 Kelopak')),
      const Divider(height: 38),
      Text('Produk gratis', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: monthly / 30, semanticsLabel: 'Progres produk gratis: $monthly dari 30 hari'),
      const SizedBox(height: 6),
      Text('$monthly dari 30 hari berturut-turut · $products hak produk'),
    ]);
  }
}
