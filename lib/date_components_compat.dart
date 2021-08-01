import 'package:flexidate/flexidate.dart';
import 'package:logging/logging.dart';

final _log = Logger("dateComponents");

/// @deprecated:  Use FlexiDate instead.
@deprecated
class DateComponents extends FlexiDateData {
  @deprecated
  DateComponents({int? day, int? month = 1, int? year})
      : super(day: day, month: month, year: year);

  @deprecated
  static DateComponents fromDateTime(DateTime dateTime) => DateComponents(
      day: dateTime.day, month: dateTime.month, year: dateTime.year);

  @deprecated
  factory DateComponents.now() => DateComponents.fromDateTime(DateTime.now());

  @deprecated
  DateComponents.fromMap(Map toParse)
      : super(
            day: _tryParseInt(toParse[kday]),
            month: _tryParseInt(toParse[kmonth]),
            year: _tryParseInt(toParse[kyear]));

  @deprecated
  static DateComponents? _fromFlexiDate(FlexiDate? flexiDate) {
    if (flexiDate == null) return null;
    return DateComponents(
        day: flexiDate.day, month: flexiDate.month, year: flexiDate.year);
  }

  @deprecated
  static DateComponents? tryFrom(input) =>
      _fromFlexiDate(FlexiDate.tryFrom(input));

  @deprecated
  static DateComponents from(input) => _fromFlexiDate(FlexiDate.from(input))!;

  @deprecated
  DateComponents copy() {
    return DateComponents(day: day, month: month, year: year);
  }

  @deprecated
  static DateComponents? tryParse(String input) {
    try {
      return _fromFlexiDate(FlexiDate.parse(input))!;
    } catch (e) {
      _log.finer("Date parse error: $e");
      return null;
    }
  }

  @deprecated
  static DateComponents parse(String toParse) =>
      _fromFlexiDate(FlexiDate.parse(toParse))!;

  @deprecated
  static DateComponents? fromJson(json) =>
      _fromFlexiDate(FlexiDate.fromJson(json));
}

int? _tryParseInt(dyn) {
  if (dyn == null) return null;
  return int.tryParse("$dyn");
}
