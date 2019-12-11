import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart';

const months = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

final _log = Logger("dateComponents");

/// Stores components of a date
class DateComponents {
  int day;
  int month;
  int year;

  DateComponents({this.day, this.month = 1, this.year});

  DateComponents.fromDateTime(DateTime dateTime)
      : assert(dateTime != null),
        day = dateTime.day,
        month = dateTime.month,
        year = dateTime.year;

  factory DateComponents.tryParse(input) {
    try {
      return DateComponents.parse(input);
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  DateComponents.fromMap(Map toParse)
      : day = tryParseInt(toParse[kday]),
        month = tryParseInt(toParse[kmonth]),
        year = tryParseInt(toParse[kyear]);

  factory DateComponents.parse(toParse) {
    if (toParse is DateComponents) return toParse;
    if (toParse is DateTime) return DateComponents.fromDateTime(toParse);
    if (toParse is Map) return DateComponents.fromMap(toParse);
    if (toParse == null) return null;

    final parseAttempt = DateTime.tryParse("$toParse".trim());
    if (parseAttempt != null) {
      return DateComponents.fromDateTime(parseAttempt);
    }

    final input = "$toParse";
    final tokenized = tokenizeString(input, splitAll: true);
    final parts = tokenized
            ?.map((value) {
              if (isNumeric(value)) {
                return value;
              } else {
                final month = DateFormat.MMMM().parseLoose(value);
                return "${month.month}";
              }
            })
            ?.map((value) => value.startsWith("0") ? value.substring(1) : value)
            ?.map((value) => int.tryParse(value))
            ?.toList() ??
        [];

    final length = parts.length;
    switch (length) {
      case 3:
        if (parts[0] > 1000) {
          return DateComponents(year: parts[0], month: parts[1], day: parts[2]);
        } else if (parts[2] > 1000) {
          return DateComponents(year: parts[2], month: parts[0], day: parts[1]);
        } else {
          return throw "Invalid date - can't find year";
        }
        break;
      case 2:
        if (parts[0] > 1000) {
          return DateComponents(year: parts[0], month: parts[1]);
        } else if (parts[1] > 1000) {
          return DateComponents(year: parts[1], month: parts[0]);
        } else {
          return DateComponents(month: parts[0], day: parts[1]);
        }
        break;
      case 1:
        if (parts[0] < 1000) return null;
        return DateComponents(year: parts[0]);
      default:
        return null;
    }
  }

  factory DateComponents.fromJson(json) {
    return DateComponents.parse(json);
  }

  toJson() {
    return {
      if (year != null) kyear: year,
      if (month != null) kmonth: month,
      if (day != null) kday: day,
    };
  }

  bool get isFullDate => year != null;

  bool get hasMonth => month != null;

  bool get hasYear => year != null;

  bool get hasDay => day != null;

  @override
  String toString() => [year, month, day]
      .where((_) => _ != null)
      .map((part) => part < 10 ? "0$part" : "$part")
      .join("-");

  DateTime toDateTime() => DateTime(year ?? 1971, month ?? 1, day ?? 1);

  DateComponents withoutDay() =>
      DateComponents(day: null, month: month, year: year);

  DateComponents withoutYear() =>
      DateComponents(day: day, month: month, year: null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateComponents &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => hash3(day, month, year);
}

List<String> tokenizeString(String input,
    {bool splitAll = false, Pattern splitOn}) {
  if (input == null) return [];
  splitOn ??=
      (splitAll == true) ? aggresiveTokenizerPattern : spaceTokenizerPattern;
  return input.split(splitOn).where((_) => _.isNotEmpty == true).toList();
}

const aggresiveTokenizer = "(,|\\/|_|\\.|-|\\s)";
final aggresiveTokenizerPattern = RegExp(aggresiveTokenizer);

const spaceTokenizer = "(\s)";
final spaceTokenizerPattern = RegExp(spaceTokenizer);

bool isNumeric(String str) => num.tryParse(str) != null;

int tryParseInt(dyn) {
  if (dyn == null) return null;
  return int.tryParse("$dyn");
}

const kyear = 'year';
const kmonth = 'month';
const kday = 'day';
