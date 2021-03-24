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
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('github.com/sunnyapp/flutter_unified_contact');
  final mock = ContactsMocks();
  channel.setMockMethodCallHandler(mock.handler);

  tearDown(() {
    mock.clear();
  });

  test('Test DateComponents compat serializes correctly', () async {
    final dc = DateComponents(month: 12, day: 23);
    final c = Contact(dates: [ContactDate.ofDate(date: dc)]);
    final map = c.toMap();
    expect(map["dates"], isA<List<Map<String, dynamic>>>());
    final dates = map["dates"] as List<Map<String, dynamic>>;
    expect(dates, hasLength(1));
    final firstDate = dates.first;
    expect(firstDate["date"], isNotNull);
    expect(firstDate["date"]["month"], equals(12));
    expect(firstDate["date"]["day"], equals(23));
    expect(firstDate["value"], equals('12-23'));
  });
}

typedef MethodHandler = Future<dynamic> Function(MethodCall call);
typedef RawMethodHandler = Future<dynamic> Function(dynamic call);
