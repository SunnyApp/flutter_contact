import 'package:flutter/services.dart';
import 'package:flutter_contact/base_contacts.dart';

import 'contact.dart';

const _channel = MethodChannel('github.com/sunnyapp/flutter_contact');
final _events = EventChannel('github.com/sunnyapp/flutter_contact_events');

// ignore: non_constant_identifier_names
final AggregateContacts =
    ContactFormService(_channel, _events, ContactMode.aggregate);
