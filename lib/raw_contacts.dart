import 'package:flutter/services.dart';
import 'package:flutter_contact/base_contacts.dart';

import 'contact.dart';

const _channel = MethodChannel('github.com/sunnyapp/flutter_raw_contact');
final _events = EventChannel('github.com/sunnyapp/flutter_raw_contact_events');

// ignore: non_constant_identifier_names
final RawContacts = ContactService(_channel, _events, ContactMode.raw);
