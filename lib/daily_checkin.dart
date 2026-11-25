/// Check-in Harian untuk Bpedia Demo v3.
///
/// Aturan murni hari WIB (+1 Kelopak per tanggal, bonus +3 tiap hari ke-7
/// beruntun, satu produk gratis tiap hari ke-30) dan halaman game siap pakai.
/// Pola: aturan murni, lalu [CheckInViewState] tak-berubah, lalu
/// [CheckInController] abstrak, lalu [CheckInPage]. Host mengisi satu
/// pengendali; [LocalCheckInController] tersedia untuk contoh dan tes.
library;

export 'src/check_in_assets.dart';
export 'src/check_in_engine.dart';
export 'src/check_in_format.dart';
export 'src/check_in_view.dart';
export 'src/kit/game_cue.dart' show GameCue;
export 'src/local_check_in_controller.dart';
export 'src/pages/check_in_page.dart';
export 'src/wib_calendar.dart';
export 'src/widgets/check_in_how_to.dart';
export 'src/widgets/check_in_month_grid.dart';
export 'src/widgets/check_in_month_progress.dart';
export 'src/widgets/check_in_reward_card.dart';
export 'src/widgets/check_in_week_strip.dart';
export 'src/widgets/lively_pose.dart';
