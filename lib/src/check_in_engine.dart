import 'package:flutter/foundation.dart';

/// Business rules of Check-in Harian. 1 Kelopak = Rp100.
abstract final class CheckInRules {
  /// Kelopak credited for every claimed WIB date.
  static const int dailyKelopak = 1;

  /// A bonus is credited on every streak day divisible by this (7, 14, 21, …).
  static const int bonusEvery = 7;

  /// Bonus Kelopak on top of [dailyKelopak] on every [bonusEvery]th day.
  static const int bonusKelopak = 3;

  /// One free-product entitlement on every streak day divisible by this.
  static const int productEvery = 30;
}

/// What a single successful check-in earns.
@immutable
final class CheckInAward {
  /// Creates an award for the claim that brings the streak to [streak].
  const CheckInAward({
    required this.streak,
    required this.dailyKelopak,
    required this.bonusKelopak,
    required this.productEntitled,
  });

  /// Consecutive WIB dates including the claimed one (1 or more).
  final int streak;

  /// Regular daily credit, always [CheckInRules.dailyKelopak].
  final int dailyKelopak;

  /// Bonus credit: [CheckInRules.bonusKelopak] on day 7, 14, 21, …, else 0.
  final int bonusKelopak;

  /// Whether this claim grants one free product (day 30, 60, …).
  final bool productEntitled;

  /// Total Kelopak credited by this claim.
  int get totalKelopak => dailyKelopak + bonusKelopak;

  @override
  bool operator ==(Object other) =>
      other is CheckInAward &&
      other.streak == streak &&
      other.dailyKelopak == dailyKelopak &&
      other.bonusKelopak == bonusKelopak &&
      other.productEntitled == productEntitled;

  @override
  int get hashCode =>
      Object.hash(streak, dailyKelopak, bonusKelopak, productEntitled);

  @override
  String toString() =>
      'CheckInAward(streak: $streak, dailyKelopak: $dailyKelopak, '
      'bonusKelopak: $bonusKelopak, productEntitled: $productEntitled)';
}

/// Evaluates a claim on WIB day [today].
///
/// [lastClaimDay] is the WIB day of the previous claim (null if none) and
/// [streak] the streak stored with it. Returns null when [today] is not after
/// [lastClaimDay]: the date is already claimed or the clock moved backwards.
/// A claim on the day right after [lastClaimDay] continues the streak; any
/// gap restarts it at 1. Earned Kelopak and products are never taken back.
CheckInAward? evaluateCheckIn({
  required int today,
  required int? lastClaimDay,
  required int streak,
}) {
  if (lastClaimDay != null && today <= lastClaimDay) return null;
  final bool continues = lastClaimDay == today - 1 && streak > 0;
  final int next = (continues ? streak : 0) + 1;
  return CheckInAward(
    streak: next,
    dailyKelopak: CheckInRules.dailyKelopak,
    bonusKelopak: next % CheckInRules.bonusEvery == 0
        ? CheckInRules.bonusKelopak
        : 0,
    productEntitled: next % CheckInRules.productEvery == 0,
  );
}

/// The streak as it stands on WIB day [today].
///
/// Equals [streak] while it is unbroken: the last claim was today or
/// yesterday (or is later than [today] after a clock rollback). Returns 0
/// when no claim exists or at least one date was missed.
int liveStreak({
  required int today,
  required int? lastClaimDay,
  required int streak,
}) {
  if (lastClaimDay == null || lastClaimDay < today - 1 || streak < 0) {
    return 0;
  }
  return streak;
}

/// Whether WIB day [today] can no longer be claimed.
///
/// True when the last claim is on [today], or on a later day after a clock
/// rollback; exactly the cases where [evaluateCheckIn] returns null.
bool isClaimedOn({required int today, required int? lastClaimDay}) =>
    lastClaimDay != null && lastClaimDay >= today;

/// Bloomed slots of the 7-day track, 0..7.
///
/// When [claimedToday] is false the next slot (index = result) is today's.
/// Day 7 claimed shows all 7 bloomed; the day after starts a new week at 0.
int filledInWeek({required int liveStreak, required bool claimedToday}) =>
    _positionInCycle(liveStreak, claimedToday, CheckInRules.bonusEvery);

/// Progress towards the next free product, 0..30.
///
/// Day 30 claimed shows 30; the day after starts the next cycle at 0.
int dayInMonthCycle({required int liveStreak, required bool claimedToday}) =>
    _positionInCycle(liveStreak, claimedToday, CheckInRules.productEvery);

int _positionInCycle(int streak, bool claimedToday, int length) {
  if (streak <= 0) return 0;
  return claimedToday ? (streak - 1) % length + 1 : streak % length;
}
