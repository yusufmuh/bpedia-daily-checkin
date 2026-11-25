import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CheckInExampleApp());

/// Produk hadiah hari ke-30 dari katalog demo Bpedia.
const CheckInRewardProduct demoRewardProduct = CheckInRewardProduct(
  code: 'P39A06S01000089',
  name: 'Animate Whitening Day Cream 10 g',
  image: AssetImage('assets/products/P39A06S01000089.webp'),
  price: 19900,
);

/// Aplikasi contoh: halaman Check-in di atas [LocalCheckInController] dan
/// panel uji untuk mengganti hari, status, dan tema.
class CheckInExampleApp extends StatefulWidget {
  /// Membuat aplikasi contoh.
  const CheckInExampleApp({super.key, this.controller});

  /// Pengendali yang dipakai; bawaan: streak 3 hari, saldo 24 Kelopak.
  final LocalCheckInController? controller;

  @override
  State<CheckInExampleApp> createState() => _CheckInExampleAppState();
}

class _CheckInExampleAppState extends State<CheckInExampleApp> {
  late final LocalCheckInController _controller =
      widget.controller ??
      LocalCheckInController(
        balance: 24,
        streak: 3,
        rewardProduct: demoRewardProduct,
      );
  ThemeMode _themeMode = ThemeMode.light;
  bool _reduceMotion = false;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check-in Harian',
      debugShowCheckedModeBanner: false,
      theme: exampleTheme(Brightness.light),
      darkTheme: exampleTheme(Brightness.dark),
      themeMode: _themeMode,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: _reduceMotion),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (BuildContext context) => CheckInPage(
          controller: _controller,
          onBack: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (BuildContext sheet) => TestPanel(
              controller: _controller,
              dark: _themeMode == ThemeMode.dark,
              reduceMotion: _reduceMotion,
              onDarkChanged: (bool value) => setState(
                () => _themeMode = value ? ThemeMode.dark : ThemeMode.light,
              ),
              onReduceMotionChanged: (bool value) =>
                  setState(() => _reduceMotion = value),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tema contoh seperti aplikasi Bpedia: Poppins, pink brand.
ThemeData exampleTheme(Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  return ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD81F57),
      brightness: brightness,
      primary: dark ? const Color(0xFFFF7AA0) : const Color(0xFFD81F57),
      surface: dark ? const Color(0xFF2A0A18) : const Color(0xFFFFF7F8),
    ),
  );
}

/// Panel uji: geser hari, susun streak, ganti status masuk, produk, jaringan,
/// tema, dan kurangi gerak. Menampilkan aksi terakhir yang dikirim halaman.
class TestPanel extends StatelessWidget {
  /// Membuat panel uji untuk [controller].
  const TestPanel({
    super.key,
    required this.controller,
    required this.dark,
    required this.reduceMotion,
    required this.onDarkChanged,
    required this.onReduceMotionChanged,
  });

  /// Pengendali lokal yang diatur.
  final LocalCheckInController controller;

  /// Tema gelap sedang aktif.
  final bool dark;

  /// Kurangi gerak sedang aktif.
  final bool reduceMotion;

  /// Dipanggil saat sakelar tema berubah.
  final ValueChanged<bool> onDarkChanged;

  /// Dipanggil saat sakelar kurangi gerak berubah.
  final ValueChanged<bool> onReduceMotionChanged;

  static const List<int> _streaks = <int>[0, 3, 6, 13, 20, 29, 34];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        final CheckInViewState state = controller.state;
        final List<String> recent = controller.actions.reversed
            .take(4)
            .toList();
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Panel uji', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Geseran hari ${controller.dayOffset}, streak '
                  '${state.streak}, saldo ${state.balance} Kelopak, produk '
                  'dimenangkan ${controller.productsWon}.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                Text('Hari', style: text.titleSmall),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: () => controller.advanceDays(1),
                      child: const Text('Besok'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.advanceDays(2),
                      child: const Text('Lompat 2 hari (bolong)'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Susun streak (sampai kemarin)', style: text.titleSmall),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final int streak in _streaks)
                      ChoiceChip(
                        label: Text('$streak'),
                        selected: state.streak == streak && !state.claimedToday,
                        onSelected: (_) => controller.seed(
                          streak: streak,
                          claimedToday: false,
                        ),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sudah masuk'),
                  value: controller.signedIn,
                  onChanged: (bool value) => controller.signedIn = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produk hadiah dari host'),
                  value: controller.rewardProduct != null,
                  onChanged: (bool value) => controller.rewardProduct = value
                      ? demoRewardProduct
                      : null,
                ),
                // Jeda dan gagal-sekali adalah ruas biasa tanpa pemberitahuan,
                // jadi sakelarnya digambar ulang secara lokal.
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setLocal) =>
                      Column(
                        children: <Widget>[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Jaringan lambat (1,2 detik)'),
                            value: controller.latency > Duration.zero,
                            onChanged: (bool value) => setLocal(
                              () => controller.latency = value
                                  ? const Duration(milliseconds: 1200)
                                  : Duration.zero,
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Gagalkan klaim berikutnya'),
                            value: controller.failNextClaim,
                            onChanged: (bool value) => setLocal(
                              () => controller.failNextClaim = value,
                            ),
                          ),
                        ],
                      ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tema gelap'),
                  value: dark,
                  onChanged: (bool value) {
                    onDarkChanged(value);
                    Navigator.pop(context);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kurangi gerak'),
                  value: reduceMotion,
                  onChanged: (bool value) {
                    onReduceMotionChanged(value);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                Text('Aksi terakhir', style: text.titleSmall),
                Text(
                  recent.isEmpty ? 'Belum ada' : recent.join(', '),
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: controller.reset,
                  child: const Text('Atur ulang'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
