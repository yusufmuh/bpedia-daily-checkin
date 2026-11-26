import 'package:daily_checkin/daily_checkin.dart';
import 'package:daily_checkin_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('contoh membuka halaman dan panel uji', (
    WidgetTester tester,
  ) async {
    final LocalCheckInController controller = LocalCheckInController(
      clock: () => DateTime.utc(2026, 11, 26, 3),
      streak: 3,
      balance: 24,
      rewardProduct: demoRewardProduct,
    );
    await tester.pumpWidget(CheckInExampleApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Check-in sekarang'), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Panel uji'), findsOneWidget);
    await tester.tap(find.text('Besok'));
    await tester.pump();
    expect(controller.dayOffset, 1);
    await tester.ensureVisible(find.text('Roda Sabtu siap diputar'));
    await tester.tap(find.text('Roda Sabtu siap diputar'));
    await tester.pump();
    expect(controller.wheelReady, isTrue);
    await tester.ensureVisible(find.text('Kurangi gerak'));
    await tester.tap(find.text('Kurangi gerak'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Panel uji'), findsNothing);
  });
}
