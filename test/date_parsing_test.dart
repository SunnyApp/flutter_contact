import 'package:flexidate/flexidate.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact/date_components_compat.dart';
import 'package:flutter_contact/paging_iterable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/iterables.dart';

import 'mock_contact_service.dart';

void main() {
  group('test date parsing - from map', () {
    test("When no data is passed, null is returned", () {
      expect(ContactDate.fromMap({}), isNull,
          reason: "Passing no data in the map should produce null");
    });

    test("When date is passed as a map", () {
      var parsedDate = ContactDate.fromMap({
        "label": "Happy Day",
        "date": {
          kmonth: 12,
          kday: 22,
          kyear: 1986,
        }
      });
      expect(parsedDate, isNotNull);
      expect(parsedDate!.label, equals("Happy Day"));
      expect(parsedDate.date, isNotNull);
      expect(parsedDate.date!.month, equals(12));
      expect(parsedDate.date!.day, equals(22));
      expect(parsedDate.date!.year, equals(1986));
    });

    test("When date is passed as a string", () {
      var parsedDate =
          ContactDate.fromMap({"label": "Happy Day", "date": "12-22"});
      expect(parsedDate, isNotNull);
      expect(parsedDate!.label, equals("Happy Day"));
      expect(parsedDate.date, isNotNull);
      expect(parsedDate.date!.month, equals(12));
      expect(parsedDate.date!.day, equals(22));
      expect(parsedDate.date!.year, isNull);
    });

    test("Date is parsed from value if no other option exists", () {
      var parsedDate = ContactDate.fromMap({"value": "12-22"});
      expect(parsedDate, isNotNull);
      expect(parsedDate!.label, isNull);
      expect(parsedDate.date, isNotNull);
      expect(parsedDate.date!.month, equals(12));
      expect(parsedDate.date!.day, equals(22));
      expect(parsedDate.date!.year, isNull);
    });

    test("Date is parsed from date key first, then value", () {
      var parsedDate = ContactDate.fromMap({"date": "12-22", "value": "12-23"});
      expect(parsedDate, isNotNull);
      expect(parsedDate!.date, isNotNull);
      expect(parsedDate.date!.month, equals(12));
      expect(parsedDate.date!.day, equals(22));
      expect(parsedDate.date!.year, isNull);
    });

    test("Unparseable date is passed through", () {
      var parsedDate = ContactDate.fromMap({"value": "I like turtles"});
      expect(parsedDate, isNotNull);
      expect(parsedDate!.date, isNull);
      expect(parsedDate.value, "I like turtles");
    });
  });
}
