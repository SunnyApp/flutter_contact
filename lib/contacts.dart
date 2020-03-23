import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/paging_iterable.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';

import 'contact.dart';
import 'contact_events.dart';
import 'group.dart';

export 'package:sunny_dart/time.dart';

export 'contact.dart';
export 'contact_events.dart';
export 'group.dart';
export 'paging_iterable.dart';

final _log = Logger("contactsService");
const _channel = MethodChannel('github.com/sunnyapp/flutter_contact');
final _events = EventChannel('github.com/sunnyapp/flutter_contact_events');
const _kidentifier = "identifier";
const _kwithThumbnails = "withThumbnails";
const _kphotoHighResolution = "photoHighResolution";

// ignore: non_constant_identifier_names
final Contacts = ContactService();

abstract class ContactsContract {
  Stream<Contact> streamContacts(
      {String query,
      bool phoneQuery,
      int bufferSize = 20,
      bool withThumbnails = true,
      bool withHiResPhoto = true,
      ContactSortOrder sortBy = const ContactSortOrder.lastName()});

  Future<int> getTotalContacts({String query, bool phoneQuery});

  PagingList<Contact> listContacts({
    String query,
    bool phoneQuery,
    int bufferSize = 20,
    bool withThumbnails = true,
    bool withHiResPhoto = true,
    ContactSortOrder sortBy = const ContactSortOrder.lastName(),
  });

  void configureLogs({Level level, LoggingHandler onLog});

  Future<Contact> getContact(String identifier, {bool withThumbnails = true, bool withHiResPhoto = true});

  Future<Uint8List> getContactImage(String identifier);

  Future<Contact> addContact(Contact contact);

  Future<bool> deleteContact(Contact contact);

  Future<Contact> updateContact(Contact contact);

  Future<Iterable<Group>> getGroups();

  Stream<ContactEvent> get contactEvents;
}

const kwithThumbnails = 'withThumbnails';
const kphotoHighResolution = 'photoHighResolution';
const klimit = 'limit';
const ksortBy = 'sortBy';
const koffset = 'offset';
const kquery = 'query';
const kphoneQuery = 'phoneQuery';
const kids = 'ids';

PageGenerator<Contact> _defaultPageGenerator(
        String query, bool phoneQuery, bool withThumbnails, bool withHiResPhoto, ContactSortOrder sortBy) =>
    (int limit, int offset) async {
      final List page = await _channel.invokeMethod('getContacts', {
        kquery: query,
        klimit: limit,
        ksortBy: sortBy?._value ?? ContactSortOrder.lastName()?._value,
        koffset: offset,
        kphoneQuery: phoneQuery,
        kwithThumbnails: withThumbnails,
        kphotoHighResolution: withHiResPhoto,
      });
      return [...page.where(notNull()).map((_) => Contact.fromMap(_))];
    };

class ContactService implements ContactsContract {
  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query]
  @override
  Stream<Contact> streamContacts({
    String query,
    bool phoneQuery,
    bool withThumbnails = true,
    bool withHiResPhoto = true,
    int bufferSize = 20,
    ContactSortOrder sortBy = const ContactSortOrder.lastName(),
  }) {
    final stream = PagingStream<Contact>(
      pageGenerator: _defaultPageGenerator(query, phoneQuery, withThumbnails, withHiResPhoto, sortBy),
      bufferSize: bufferSize,
    );
    return stream;
  }

  @override
  Future<Uint8List> getContactImage(String identifier) async {
    if (identifier == null) return null;
    final data = await _channel.invokeMethod('getContactImage', {'identifier': identifier});
    return data as Uint8List;
  }

  @override
  Future<int> getTotalContacts({
    String query,
    bool phoneQuery,
  }) {
    return _channel.invokeMethod('getTotalContacts', {
      kquery: query,
      kphoneQuery: phoneQuery,
    });
  }

  @override
  PagingList<Contact> listContacts(
      {String query,
      bool phoneQuery,
      bool withThumbnails = true,
      bool withHiResPhoto = true,
      int bufferSize = 20,
      ContactSortOrder sortBy = const ContactSortOrder.lastName()}) {
    final list = PagingList<Contact>(
      pageGenerator: _defaultPageGenerator(query, phoneQuery, withThumbnails, withHiResPhoto, sortBy),
      bufferSize: bufferSize,
      length: getTotalContacts(query: query, phoneQuery: phoneQuery),
    );
    return list;
  }

  /// Configures logging.  FlutterPhoneState uses the [logging] plugin.
  @override
  void configureLogs({Level level, LoggingHandler onLog}) {
    configureLogging(LogConfig(logLevels: {"contactsService": level}, handler: onLog ?? LoggingHandler.dev()));
  }

  /// Retrieves a single contact by identifier
  @override
  Future<Contact> getContact(String identifier, {bool withThumbnails = true, bool withHiResPhoto = true}) async {
    final fromChannel = await _channel.invokeMethod('getContact', <String, dynamic>{
      _kidentifier: identifier,
      _kwithThumbnails: withThumbnails,
      _kphotoHighResolution: withHiResPhoto,
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

const _kSortFirstName = "firstName";
const _kSortLastName = "lastName";

class ContactSortOrder extends Equatable {
  final String _value;

  const ContactSortOrder.lastName() : _value = _kSortLastName;

  const ContactSortOrder.firstName() : _value = _kSortFirstName;

  @override
  List<Object> get props => [_value];
}
