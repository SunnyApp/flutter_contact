import 'package:flexidate/flexidate.dart';

extension FlexiDateFormat on FlexiDate {
  String format() {
    return [year, month, day].where((d) => d != null).join('-');
  }
}

extension DateTimeFormatExt on DateTime {
  String format() {
    return toIso8601String();
  }
}
