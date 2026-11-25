import 'package:daily_checkin/daily_checkin.dart';
import 'package:daily_checkin_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/shot.dart';

void main() {
  testWidgets('panel uji terbuka di atas halaman', (WidgetTester tester) async {
    final LocalCheckInController controller = LocalCheckInController(
      clock: () => DateTime.utc(2026, 11, 26, 3),
      streak: 3,
      balance: 24,
      rewardProduct: demoRewardProduct,
    );
    await pumpShot(tester, CheckInExampleApp(controller: controller));
    await tester.tap(find.byTooltip('Kembali'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await settleImages(tester);
    await saveShot(tester, 'contoh_panel_uji');
  });
}
