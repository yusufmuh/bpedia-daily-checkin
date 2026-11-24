import 'package:flutter/material.dart';

/// What [CheckInClaimButton] offers.
enum CheckInButtonState {
  /// Today can be claimed: "Ambil 1 Kelopak".
  ready,

  /// Today is claimed: "Sudah check-in hari ini", not tappable.
  claimed,
}

/// The single primary action of Check-in Harian.
///
/// A full-width [FilledButton] at least 52 dp high. In
/// [CheckInButtonState.ready] it reads "Ambil 1 Kelopak" and calls
/// [onPressed] (pass null to disable it while the host is busy). In
/// [CheckInButtonState.claimed] it is disabled, reads
/// "Sudah check-in hari ini" with a check icon and shows [claimedHint]
/// below, for example "Kembali besok mulai 00.00 WIB untuk Hari ke-4".
class CheckInClaimButton extends StatelessWidget {
  /// Creates the claim button.
  const CheckInClaimButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.claimedHint,
  });

  /// Whether today is still claimable.
  final CheckInButtonState state;

  /// Called on tap in [CheckInButtonState.ready]; ignored once claimed.
  final VoidCallback? onPressed;

  /// Next step shown under the button once claimed.
  final String claimedHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool claimed = state == CheckInButtonState.claimed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: claimed ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            disabledBackgroundColor: claimed ? scheme.primaryContainer : null,
            disabledForegroundColor: claimed ? scheme.onPrimaryContainer : null,
            disabledIconColor: claimed ? scheme.secondary : null,
          ),
          icon: Icon(claimed ? Icons.check_circle : Icons.local_florist),
          label: Text(
            claimed ? 'Sudah check-in hari ini' : 'Ambil 1 Kelopak',
            textAlign: TextAlign.center,
          ),
        ),
        if (claimed && claimedHint.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            claimedHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
