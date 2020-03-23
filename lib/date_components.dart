import 'package:sunny_dart/time.dart' as _;

@deprecated
const months = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

/// Stores components of a date
/// deprecated: Use DateComponents from `sunny_dart` package instead
@deprecated
class DateComponents extends _.DateComponents {
  DateComponents({int day, int month = 1, int year}) : super();

  factory DateComponents.fromDateTime(DateTime dateTime) => _.DateComponents.fromDateTime(dateTime);

  factory DateComponents.tryParse(input) => _.DateComponents.tryParse(input);

  DateComponents.fromMap(Map toParse) : super.fromMap(toParse);

  factory DateComponents.parse(toParse) => _.DateComponents.parse(toParse);

  factory DateComponents.fromJson(json) => _.DateComponents.fromJson(json);
}

//List<String> tokenizeString(String input, {bool splitAll = false, Pattern splitOn}) {
//  if (input == null) return [];
//  splitOn ??= (splitAll == true) ? aggresiveTokenizerPattern : spaceTokenizerPattern;
//  return input.split(splitOn).where((_) => _.isNotEmpty == true).toList();
//}
//
//const aggresiveTokenizer = "(,|\\/|_|\\.|-|\\s)";
//final aggresiveTokenizerPattern = RegExp(aggresiveTokenizer);
//
//const spaceTokenizer = "(\s)";
//final spaceTokenizerPattern = RegExp(spaceTokenizer);
//
//bool isNumeric(String str) => num.tryParse(str) != null;
//
