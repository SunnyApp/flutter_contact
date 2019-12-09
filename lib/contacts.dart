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

// ignore: non_constant_identifier_names
final Contacts = _Contacts();

abstract class ContactsContract {
  Future<Iterable<Contact>> getContacts({String query, bool withThumbnails = true, bool withHiResPhoto = true});
  void configureLogs({Level level, Logging onLog});
  Future<Iterable<Contact>> getContactsForPhone(String phone, {bool withThumbnails = true, bool withHiResPhoto = true});
  Future<Contact> getContact(String identifier, {bool withThumbnails = true, bool withHiResPhoto = true});
  Future<Contact> addContact(Contact contact);
  Future<bool> deleteContact(Contact contact);
  Future<Contact> updateContact(Contact contact);
  Future<Iterable<Group>> getGroups();
  Stream<ContactEvent> get contactEvents;
}

class _Contacts extends ContactsContract {
  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  @override
  Future<Iterable<Contact>> getContacts({String query, bool withThumbnails = true, bool withHiResPhoto = true}) async {
    Iterable contacts = await _channel.invokeMethod('getContacts',
        <String, dynamic>{'query': query, 'withThumbnails': withThumbnails, 'photoHighResolution': withHiResPhoto});
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Configures logging.  FlutterPhoneState uses the [logging] plugin.
  @override
  void configureLogs({Level level, Logging onLog}) {
    configureLogging(logger: _log, level: level, onLog: onLog);
  }

  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  @override
  Future<Iterable<Contact>> getContactsForPhone(String phone,
      {bool withThumbnails = true, bool withHiResPhoto = true}) async {
    if (phone == null || phone.isEmpty) return Iterable.empty();

    Iterable contacts = await _channel.invokeMethod('getContactsForPhone',
        <String, dynamic>{'phone': phone, 'withThumbnails': withThumbnails, 'photoHighResolution': withHiResPhoto});
    return contacts.map((m) => Contact.fromMap(m));
  }

  /// Retrieves a single contact by identifier
  @override
  Future<Contact> getContact(String identifier, {bool withThumbnails = true, bool withHiResPhoto = true}) async {
    final fromChannel = await _channel.invokeMethod('getContact', <String, dynamic>{
      "identifier": identifier,
      "withThumbnails": withThumbnails,
      "photoHighResolution": withHiResPhoto,
    });
    if (fromChannel == null) return null;
    return Contact.fromMap(fromChannel);
  }

  /// Adds the [contact] to the device contact list - returns the saved contact, so you can access the [identifier]
  @override
  Future<Contact> addContact(Contact contact) async {
    final map = await _channel.invokeMethod('addContact', contact.toMap());
    return Contact.fromMap(map);
  }

  /// Deletes the [contact] if it has a valid identifier
  @override
  Future<bool> deleteContact(Contact contact) => _channel.invokeMethod('deleteContact', contact.toMap());

  /// Updates the [contact] if it has a valid identifier
  @override
  Future<Contact> updateContact(Contact contact) async {
    final map = await _channel.invokeMethod('updateContact', contact.toMap());
    return Contact.fromMap(map);
  }

  /// Updates the [contact] if it has a valid identifier
  @override
  Future<Iterable<Group>> getGroups() async {
    Iterable groups = await _channel.invokeMethod('getGroups', {});
    return groups.map((g) => Group.fromMap(g));
  }

  Stream<dynamic> _eventStream;

  @override
  Stream<ContactEvent> get contactEvents {
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
