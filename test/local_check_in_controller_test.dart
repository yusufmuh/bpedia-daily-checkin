import 'package:daily_checkin/daily_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/check_in_harness.dart';

void main() {
  group('LocalCheckInController', () {
    test('riwayat awal dari streak dan claimedToday', () {
      final LocalCheckInController c = localController();
      expect(c.state.streak, 3);
      expect(c.state.claimedToday, isFalse);
      expect(c.state.balance, 24);
      expect(c.state.signedIn, isTrue);
    });

    test('klaim menambah saldo, streak, dan memberi tahu pendengar', () async {
      final LocalCheckInController c = localController();
      int notified = 0;
      c.addListener(() => notified++);
      final CheckInClaimResult? result = await c.claim();
      expect(result, isNotNull);
      expect(result!.award.streak, 4);
      expect(result.award.totalKelopak, 1);
      expect(result.balance, 25);
      expect(c.state.claimedToday, isTrue);
      expect(c.state.balance, 25);
      expect(notified, greaterThan(0));
    });

    test('klaim kedua di hari yang sama ditolak', () async {
      final LocalCheckInController c = localController();
      await c.claim();
      expect(await c.claim(), isNull);
      expect(c.state.balance, 25);
    });

    test('tamu tidak bisa klaim', () async {
      final LocalCheckInController c = localController(signedIn: false);
      expect(await c.claim(), isNull);
      expect(c.state.signedIn, isFalse);
      expect(c.state.balance, 0);
    });

    test('hari berikutnya melanjutkan streak', () async {
      final LocalCheckInController c = localController();
      await c.claim();
      c.advanceDays(1);
      expect(c.dayOffset, 1);
      expect(c.state.claimedToday, isFalse);
      expect(c.state.streak, 4);
      final CheckInClaimResult? next = await c.claim();
      expect(next!.award.streak, 5);
    });

    test('bolong sehari memutus streak', () async {
      final LocalCheckInController c = localController();
      await c.claim();
      c.advanceDays(2);
      expect(c.state.streak, 0);
      final CheckInClaimResult? next = await c.claim();
      expect(next!.award.streak, 1);
    });

    test('hari ke-7 memberi bonus +3', () async {
      final LocalCheckInController c = localController(streak: 6);
      final CheckInClaimResult? r = await c.claim();
      expect(r!.award.bonusKelopak, 3);
      expect(r.award.totalKelopak, 4);
      expect(r.balance, 28);
    });

    test('hari ke-30 memberi produk host', () async {
      final LocalCheckInController c = localController(streak: 29);
      final CheckInClaimResult? r = await c.claim();
      expect(r!.award.productEntitled, isTrue);
      expect(r.product, demoRewardProduct);
      expect(c.productsWon, 1);
    });

    test('hari ke-30 tanpa produk host: hak tetap, produk null', () async {
      final LocalCheckInController c = localController(
        streak: 29,
        withProduct: false,
      );
      final CheckInClaimResult? r = await c.claim();
      expect(r!.award.productEntitled, isTrue);
      expect(r.product, isNull);
    });

    test('jeda jaringan menandai busy selama klaim', () async {
      final LocalCheckInController c = localController(
        latency: const Duration(milliseconds: 20),
      );
      final Future<CheckInClaimResult?> pending = c.claim();
      expect(c.state.busy, isTrue);
      expect(await c.claim(), isNull);
      await pending;
      expect(c.state.busy, isFalse);
      expect(c.state.claimedToday, isTrue);
    });

    test('failNextClaim melempar sekali lalu pulih', () async {
      final LocalCheckInController c = localController()..failNextClaim = true;
      await expectLater(c.claim(), throwsStateError);
      expect(c.state.claimedToday, isFalse);
      expect(c.state.balance, 24);
      expect(await c.claim(), isNotNull);
    });

    test('reset mengosongkan riwayat, saldo, geseran, dan catatan', () async {
      final LocalCheckInController c = localController(streak: 5);
      await c.claim();
      c
        ..advanceDays(3)
        ..openShop()
        ..reset();
      expect(c.state.streak, 0);
      expect(c.state.balance, 0);
      expect(c.dayOffset, 0);
      expect(c.actions, isEmpty);
      expect(c.productsWon, 0);
    });

    test('seed menyusun ulang riwayat dan saldo', () {
      final LocalCheckInController c = localController()
        ..seed(streak: 13, claimedToday: true, balance: 70);
      expect(c.state.streak, 13);
      expect(c.state.claimedToday, isTrue);
      expect(c.state.balance, 70);
      c.seed(streak: 0, claimedToday: false);
      expect(c.state.streak, 0);
      expect(c.state.balance, 70);
    });

    test('aksi keluar dan suara tercatat berurutan', () {
      final LocalCheckInController c = localController()
        ..openLogin()
        ..openShop()
        ..openCart()
        ..openProduct('P1')
        ..openTerms()
        ..playCue(GameCue.claim);
      expect(c.actions, <String>[
        'openLogin',
        'openShop',
        'openCart',
        'openProduct:P1',
        'openTerms',
        'cue:claim',
      ]);
    });

    test('setSoundOn dan signedIn mengubah keadaan', () {
      final LocalCheckInController c = localController();
      int notified = 0;
      c.addListener(() => notified++);
      c.setSoundOn(false);
      expect(c.state.soundOn, isFalse);
      c.signedIn = false;
      expect(c.state.signedIn, isFalse);
      c.signedIn = false;
      expect(notified, 2);
    });

    test('pergantian hari WIB berikutnya pukul 00.00 WIB', () {
      final LocalCheckInController c = localController();
      expect(c.now(), fixedNow);
      expect(c.state.nextResetAt, DateTime.utc(2026, 11, 26, 17));
      expect(c.today, wibDayOf(fixedNow));
    });

    test('rewardProduct bisa diganti host', () {
      final LocalCheckInController c = localController(withProduct: false);
      expect(c.state.rewardProduct, isNull);
      c.rewardProduct = demoRewardProduct;
      expect(c.state.rewardProduct, demoRewardProduct);
    });
  });
}
