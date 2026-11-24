/// Western Indonesia Time (WIB) is UTC+07:00 all year, without daylight saving.
const int _wibOffsetMillis = 7 * Duration.millisecondsPerHour;

/// The WIB calendar day of [instant], counted in days since 1 January 1970.
///
/// Day 0 is Thursday 1 January 1970 (WIB). A new day starts at 00.00 WIB,
/// which is 17.00 UTC of the previous date. The time zone of [instant] does
/// not matter: only the absolute moment is used. Instants before the epoch
/// are floored, so 23.59 WIB on 31 December 1969 is day -1.
int wibDayOf(DateTime instant) {
  final int shifted = instant.millisecondsSinceEpoch + _wibOffsetMillis;
  final int remainder = shifted % Duration.millisecondsPerDay;
  return (shifted - remainder) ~/ Duration.millisecondsPerDay;
}

/// ISO weekday of [wibDay]: 1 = Monday … 6 = Saturday, 7 = Sunday.
///
/// Matches [DateTime.monday] … [DateTime.sunday].
int wibWeekdayOf(int wibDay) => ((wibDay + 3) % DateTime.daysPerWeek) + 1;

/// The calendar date of [wibDay] as a UTC [DateTime] at midnight.
///
/// Read `year`, `month` and `day` from the result to get the WIB date; the
/// time part carries no meaning. `wibDayOf(wibDateOf(d)) == d` for every `d`.
DateTime wibDateOf(int wibDay) =>
    DateTime.utc(1970).add(Duration(days: wibDay));
