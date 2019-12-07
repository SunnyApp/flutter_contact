import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'contact.dart';
import 'contact_events.dart';
import 'group.dart';
import 'logging.dart';

export 'contact.dart';
export 'contact_events.dart';
export 'group.dart';

final _log = Logger("contactsService");
const _channel = MethodChannel('github.com/sunnyapp/flutter_contact');
final _events = EventChannel('github.com/sunnyapp/flutter_contact_events');

class Contacts {
  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<Contact>> getContacts(
      {String query, bool withThumbnails = true, bool photoHighResolution = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContacts', <String, dynamic>{
      'query': query,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Configures logging.  FlutterPhoneState uses the [logging] plugin.
  static void configureLogs({Level level, Logging onLog}) {
    configureLogging(logger: _log, level: level, onLog: onLog);
  }

  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  static Future<Iterable<Contact>> getContactsForPhone(String phone,
      {bool withThumbnails = true, bool photoHighResolution = true}) async {
    if (phone == null || phone.isEmpty) return Iterable.empty();

    Iterable contacts = await _channel.invokeMethod('getContactsForPhone', <String, dynamic>{
      'phone': phone,
      'withThumbnails': withThumbnails,
      'photoHighResolution': photoHighResolution
    });
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Retrieves a single contact by identifier
  static Future<Contact> getContact(
    String identifier, {
    bool withThumbnails = true,
    bool photoHighResolution = true,
  }) async {
    final fromChannel = await _channel.invokeMethod('getContact', <String, dynamic>{
      "identifier": identifier,
      "withThumbnails": withThumbnails,
      "photoHighResolution": photoHighResolution,
    });
    return Contact.fromMap(fromChannel);
  }

  /// Adds the [contact] to the device contact list - returns the saved contact, so you can access the [identifier]
  static Future<Contact> addContact(Contact contact) async {
    final map = await _channel.invokeMethod('addContact', contact.toMap());
    return Contact.fromMap(map);
  }

  /// Deletes the [contact] if it has a valid identifier
  static Future deleteContact(Contact contact) => _channel.invokeMethod('deleteContact', contact.toMap());

  /// Updates the [contact] if it has a valid identifier
  static Future<Contact> updateContact(Contact contact) async {
    final map = await _channel.invokeMethod('updateContact', contact.toMap());
    return Contact.fromMap(map);
  }

  /// Updates the [contact] if it has a valid identifier
  static Future<Iterable<Group>> getGroups() async {
    Iterable groups = await _channel.invokeMethod('getGroups', {});
    return groups.map((g) => Group.fromMap(g));
  }

  static Stream<dynamic> _eventStream;

  static Stream<ContactEvent> get contactEvents {
    _eventStream ??= _events.receiveBroadcastStream();
    return _eventStream.map((final input) {
      if (input is! Map) {
        _log.severe("Invalid contact event.  Not passing through");
        return null;
      }

      final dyn = (input as Map).cast<String, dynamic>();

      try {
        String eventType = dyn["event"] as String;
        ContactEvent event;
        switch (eventType) {
          case "contacts-changed":
            event = ContactsChangedEvent();
            break;
          default:
            print("Unable to determine type");
            event = UnknownContactEvent(dyn);
            break;
        }
        _log.fine("Contact service event: $event");
        return event;
      } catch (e, stack) {
        _log.severe("Error building event: $e", e, stack);
        return null;
      }
    }).where((event) => event != null);
  }
}
