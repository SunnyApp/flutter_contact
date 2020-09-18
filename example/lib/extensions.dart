import 'package:sunny_dart/time.dart';

extension DateComponentsFormat on DateComponents {
  String format() {
    return [year, month, day].where((d) => d != null).join('-');
  }
}

extension DateTimeFormatExt on DateTime {
  String format() {
    return toIso8601String();
  }
}
