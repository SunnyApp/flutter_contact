import 'package:flutter/services.dart';
import 'package:flutter_contact/base_contacts.dart';

import 'contact.dart';

const _channel = MethodChannel('github.com/sunnyapp/flutter_unified_contact');
final _events =
    EventChannel('github.com/sunnyapp/flutter_unified_contact_events');

// ignore: non_constant_identifier_names
final UnifiedContacts =
    ContactFormService(_channel, _events, ContactMode.unified);
